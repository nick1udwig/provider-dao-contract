// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IProviderDaos} from "./IProviderDaos.sol";
import {Proposal, AddMemberProposal, ChangeMemberProposal, ChangeParametersProposal, ChangeIsPermissionedProposal} from "./Proposals.sol";

/// @title Multi-DAO Contract for managing decentralized organizations
contract ProviderDaos is IProviderDaos {


    // state


    struct Member {
        address addr;
        bytes32 nodeId;
        bool isMember;
        bool isProvider;
        bool isRouter;
    }

    struct Dao {
        mapping(address => Member) members;
        mapping(uint256 => address) proposals;
        uint256 numMembers;
        uint256 numProposals;
        uint256 queueResponseTimeoutSeconds;
        uint256 serveTimeoutSeconds;
        uint256 maxOutstandingPayments;
        bool isPermissioned;
    }

    mapping(bytes32 => Dao) public daos;
    uint256 public numDaos;

    event DaoCreated(bytes32 daoId);
    event DaoDestroyed(bytes32 daoId);
    event MemberAdded(bytes32 daoId, address member, bytes32 nodeId, bool isProvider, bool isRouter);
    event MemberChanged(bytes32 daoId, address member, bytes32 nodeId, bool isMember, bool isProvider, bool isRouter);
    event ParametersChanged(bytes32 daoId, uint256 queueResponseTimeoutSeconds, uint256 serveTimeoutSeconds, uint256 maxOutstandingPayments);
    event IsPermissionedChanged(bytes32 daoId, bool isPermissioned);
    event ProposalCreated(bytes32 daoId, uint256 proposalId);
    event Voted(bytes32 daoId, address voter, uint256 proposalId, bool vote);


    // create or destroy a DAO


    function createDao(bytes32 _nodeId) public returns (bytes32) {
        bytes32 daoId = keccak256(abi.encodePacked(msg.sender, block.timestamp, numDaos));
        numDaos++;

        Dao storage dao = daos[daoId];
        dao.members[msg.sender] = Member(msg.sender, _nodeId, true, false, true);
        dao.numMembers += 1;
        dao.numProposals = 0;
        dao.queueResponseTimeoutSeconds = 1;  // NOTE: hardcode
        dao.serveTimeoutSeconds = 60;         // NOTE: hardcode
        dao.maxOutstandingPayments = 3;       // NOTE: hardcode
        dao.isPermissioned = true;

        emit DaoCreated(daoId);
        emit MemberAdded(daoId, msg.sender, _nodeId, false, true);

        return daoId;
    }

    function destroyDao(bytes32 daoId) private {
        require(daos[daoId].numMembers == 0, "Cannot destroy a DAO that still has members");
        require(numDaos > 0, "Cannot destory a non-existent DAO");
        numDaos--;
        delete daos[daoId];

        emit DaoDestroyed(daoId);
    }

    // utility


    function getVotingThreshold(bytes32 daoId) public view returns (uint256) {
        // for now, just assume majority rules
        require(daos[daoId].numMembers > 0, "An empty DAO has no voting threshold");
        return 1 + (daos[daoId].numMembers - 1) / 2;
    }

    function getProposalAddress(bytes32 daoId, uint256 proposalId) public view returns (address) {
        return daos[daoId].proposals[proposalId];
    }

    function getMemberInfo(bytes32 daoId, address memberAddress) public view returns (bytes32 nodeId, bool isMember, bool isProvider, bool isRouter) {
        Member memory member = daos[daoId].members[memberAddress];
        return (member.nodeId, member.isMember, member.isProvider, member.isRouter);
    }

    function getQueueResponseTimeoutSeconds(bytes32 daoId) public view returns (uint256) {
        return daos[daoId].queueResponseTimeoutSeconds;
    }

    function getServeTimeoutSeconds(bytes32 daoId) public view returns (uint256) {
        return daos[daoId].serveTimeoutSeconds;
    }

    function getMaxOutstandingPayments(bytes32 daoId) public view returns (uint256) {
        return daos[daoId].maxOutstandingPayments;
    }

    function getIsPermissioned(bytes32 daoId) public view returns (bool) {
        return daos[daoId].isPermissioned;
    }


    // governance


    modifier onlyMember(bytes32 daoId) {
        require(daos[daoId].members[msg.sender].isMember, "Not a member");
        _;
    }

    function addMember(bytes32 daoId, uint256 proposalId, address _member, bytes32 _nodeId) public {
        // TODO: check and deny if nodeId already exists in members

        Dao storage dao = daos[daoId];
        if (dao.isPermissioned) {
            require(msg.sender == dao.proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        }
        require(!dao.members[_member].isMember, "Already a member");
        dao.members[_member] = Member(_member, _nodeId, true, true, false);
        dao.numMembers += 1;
        emit MemberAdded(daoId, _member, _nodeId, true, false);
    }

    function changeMember(bytes32 daoId, uint256 proposalId, address _member, bool newIsMember, bool newIsProvider, bool newIsRouter) public {
        Dao storage dao = daos[daoId];
        bytes32 _nodeId = dao.members[_member].nodeId;
        require(msg.sender == dao.proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        require(dao.members[_member].isMember, "Must be a member");
        if (dao.members[_member].isMember != newIsMember) {
            dao.members[_member].isMember = newIsMember;
        }
        if (dao.members[_member].isProvider != newIsProvider) {
            dao.members[_member].isProvider = newIsProvider;
        }
        if (dao.members[_member].isRouter != newIsRouter) {
            dao.members[_member].isRouter = newIsRouter;
        }
        if (!newIsMember) {
            dao.numMembers -= 1;
            if (dao.numMembers == 0) {
                destroyDao(daoId);
            }
        }
        emit MemberChanged(daoId, _member, _nodeId, newIsMember, newIsProvider, newIsRouter);
    }

    function changeParameters(bytes32 daoId, uint256 proposalId, uint256 newQueueResponseTimeoutSeconds, uint256 newServeTimeoutSeconds, uint256 newMaxOutstandingPayments) public {
        Dao storage dao = daos[daoId];
        require(msg.sender == dao.proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        if (dao.queueResponseTimeoutSeconds != newQueueResponseTimeoutSeconds) {
            dao.queueResponseTimeoutSeconds = newQueueResponseTimeoutSeconds;
        }
        if (dao.serveTimeoutSeconds != newServeTimeoutSeconds) {
            dao.serveTimeoutSeconds = newServeTimeoutSeconds;
        }
        if (dao.maxOutstandingPayments != newMaxOutstandingPayments) {
            dao.maxOutstandingPayments = newMaxOutstandingPayments;
        }
        emit ParametersChanged(daoId, newQueueResponseTimeoutSeconds, newServeTimeoutSeconds, newMaxOutstandingPayments);
    }

    function changeIsPermissioned(bytes32 daoId, uint256 proposalId, bool newIsPermissioned) public {
        Dao storage dao = daos[daoId];
        require(msg.sender == dao.proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        if (dao.isPermissioned != newIsPermissioned) {
            dao.isPermissioned = newIsPermissioned;
        }
        emit IsPermissionedChanged(daoId, newIsPermissioned);
    }

    function createProposalAddMember(bytes32 daoId, address _newMember, bytes32 _nodeId) public onlyMember(daoId) returns (uint256) {
        Dao storage dao = daos[daoId];
        require(!dao.members[_newMember].isMember, "Cannot re-add a member");
        uint256 proposalId = dao.numProposals++;
        AddMemberProposal newProposal = new AddMemberProposal(address(this), daoId, proposalId, msg.sender, _newMember, _nodeId);
        dao.proposals[proposalId] = address(newProposal);
        emit ProposalCreated(daoId, proposalId);
        return proposalId;
    }

    function createProposalChangeMember(bytes32 daoId, address member, bool _newIsMember, bool _newIsProvider, bool _newIsRouter) public onlyMember(daoId) returns (uint256) {
        Dao storage dao = daos[daoId];
        require(dao.members[member].isMember, "Can only change existing members");
        uint256 proposalId = dao.numProposals++;
        ChangeMemberProposal newProposal = new ChangeMemberProposal(address(this), daoId, proposalId, msg.sender, member, _newIsMember, _newIsProvider, _newIsRouter);
        dao.proposals[proposalId] = address(newProposal);
        emit ProposalCreated(daoId, proposalId);
        return proposalId;
    }

    function createProposalChangeParameters(bytes32 daoId, uint256 _newQueueResponseTimeoutSeconds, uint256 _newServeTimeoutSeconds, uint256 _newMaxOutstandingPayments) public onlyMember(daoId) returns (uint256) {
        Dao storage dao = daos[daoId];
        uint256 proposalId = dao.numProposals++;
        ChangeParametersProposal newProposal = new ChangeParametersProposal(address(this), daoId, proposalId, msg.sender, _newQueueResponseTimeoutSeconds, _newServeTimeoutSeconds, _newMaxOutstandingPayments);
        dao.proposals[proposalId] = address(newProposal);
        emit ProposalCreated(daoId, proposalId);
        return proposalId;
    }

    function createProposalChangeIsPermissioned(bytes32 daoId, bool _newIsPermissioned) public onlyMember(daoId) returns (uint256) {
        Dao storage dao = daos[daoId];
        uint256 proposalId = dao.numProposals++;
        ChangeIsPermissionedProposal newProposal = new ChangeIsPermissionedProposal(address(this), daoId, proposalId, msg.sender, _newIsPermissioned);
        dao.proposals[proposalId] = address(newProposal);
        emit ProposalCreated(daoId, proposalId);
        return proposalId;
    }

    function vote(bytes32 daoId, uint256 _proposalId, bool approve) public onlyMember(daoId) {
        Proposal(daos[daoId].proposals[_proposalId]).vote(approve);
        emit Voted(daoId, msg.sender, _proposalId, approve);
    }
}
