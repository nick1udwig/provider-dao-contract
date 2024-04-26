// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IProviderDaos} from "./IProviderDaos.sol";
import {Proposal, AddMemberProposal, ChangeMemberProposal, ChangeParametersProposal, ChangeIsPermissionedProposal} from "./Proposals.sol";

/// @title Multi-DAO Contract for managing decentralized organizations
contract ProviderDaos is IProviderDaos {


    // state


    struct Member {
        address addr;
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


    // create a new DAO


    event DaoCreated(bytes32 daoId);
    event MemberAdded(bytes32 daoId, address member);
    event MemberChanged(bytes32 daoId, address member, bool isMember, bool isProvider, bool isRouter);
    event ParametersChanged(bytes32 daoId, uint256 queueResponseTimeoutSeconds, uint256 serveTimeoutSeconds, uint256 maxOutstandingPayments);
    event IsPermissionedChanged(bytes32 daoId, bool isPermissioned);
    event ProposalCreated(bytes32 daoId, uint256 proposalId);
    event Voted(bytes32 daoId, address voter, uint256 proposalId, bool vote);

    function createDao() public returns (bytes32) {
        bytes32 daoId = keccak256(abi.encodePacked(msg.sender, block.timestamp, numDaos));
        numDaos++;

        Dao storage dao = daos[daoId];
        dao.members[msg.sender] = Member(msg.sender, true, false, true);
        dao.numProposals = 0;
        dao.isPermissioned = true;

        emit DaoCreated(daoId);
        emit MemberAdded(daoId, msg.sender);

        return daoId;
    }


    // utility


    function getVotingThreshold(bytes32 daoId) public view returns (uint256) {
        // for now, just assume majority rules
        return 1 + (daos[daoId].numMembers - 1) / 2;
    }

    function getProposalAddress(bytes32 daoId, uint256 proposalId) public view returns (address) {
        return daos[daoId].proposals[proposalId];
    }

    function getMemberInfo(bytes32 daoId, address memberAddress) public view returns (bool isMember, bool isProvider, bool isRouter) {
        Member memory member = daos[daoId].members[memberAddress];
        return (member.isMember, member.isProvider, member.isRouter);
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

    function addMember(bytes32 daoId, uint256 proposalId, address _member) public {
        if (daos[daoId].isPermissioned) {
            require(msg.sender == daos[daoId].proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        }
        require(!daos[daoId].members[_member].isMember, "Already a member");
        daos[daoId].members[_member] = Member(_member, true, true, false);
        emit MemberAdded(daoId, _member);
    }

    function changeMember(bytes32 daoId, uint256 proposalId, address _member, bool newIsMember, bool newIsProvider, bool newIsRouter) public {
        require(msg.sender == daos[daoId].proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        require(daos[daoId].members[_member].isMember, "Must be a member");
        if (daos[daoId].members[_member].isMember != newIsMember) {
            daos[daoId].members[_member].isMember = newIsMember;
        }
        if (daos[daoId].members[_member].isProvider != newIsProvider) {
            daos[daoId].members[_member].isProvider = newIsProvider;
        }
        if (daos[daoId].members[_member].isRouter != newIsRouter) {
            daos[daoId].members[_member].isRouter = newIsRouter;
        }
        emit MemberChanged(daoId, _member, newIsMember, newIsProvider, newIsRouter);
    }

    function changeParameters(bytes32 daoId, uint256 proposalId, uint256 newQueueResponseTimeoutSeconds, uint256 newServeTimeoutSeconds, uint256 newMaxOutstandingPayments) public {
        require(msg.sender == daos[daoId].proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        if (daos[daoId].queueResponseTimeoutSeconds != newQueueResponseTimeoutSeconds) {
            daos[daoId].queueResponseTimeoutSeconds = newQueueResponseTimeoutSeconds;
        }
        if (daos[daoId].serveTimeoutSeconds != newServeTimeoutSeconds) {
            daos[daoId].serveTimeoutSeconds = newServeTimeoutSeconds;
        }
        if (daos[daoId].maxOutstandingPayments != newMaxOutstandingPayments) {
            daos[daoId].maxOutstandingPayments = newMaxOutstandingPayments;
        }
        emit ParametersChanged(daoId, newQueueResponseTimeoutSeconds, newServeTimeoutSeconds, newMaxOutstandingPayments);
    }

    function changeIsPermissioned(bytes32 daoId, uint256 proposalId, bool newIsPermissioned) public {
        require(msg.sender == daos[daoId].proposals[proposalId], "Only Proposal can execute permissioned AddMember");
        if (daos[daoId].isPermissioned != newIsPermissioned) {
            daos[daoId].isPermissioned = newIsPermissioned;
        }
        emit IsPermissionedChanged(daoId, newIsPermissioned);
    }

    function createProposalAddMember(bytes32 daoId, address _newMember) public onlyMember(daoId) returns (uint256) {
        Dao storage dao = daos[daoId];
        require(!dao.members[_newMember].isMember, "Cannot re-add a member");
        uint256 proposalId = dao.numProposals++;
        AddMemberProposal newProposal = new AddMemberProposal(address(this), daoId, proposalId, msg.sender, _newMember);
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
