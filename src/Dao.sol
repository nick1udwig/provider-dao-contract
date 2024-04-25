// SPDX-License-Identifier: MIT
pragma solidity ^0.9.0;

import "./DaoInterface.sol";
import "./Proposals.sol";

/// @title Multi-DAO Contract for managing decentralized organizations
contract Dao {
    // state

    struct Member {
        address addr;
        bool isMember;
        bool isProvider;
        bool isRouter;
    }

    // struct Proposal {
    //     address proposer;
    //     uint256 votesFor;
    //     uint256 votesAgainst;
    //     mapping(address => bool) voted;
    //     bool executed;
    // }

    // uint256 constant PROPOSAL_ADD_MEMBER = 1;
    // uint256 constant PROPOSAL_CHANGE_MEMBER = 2;
    // uint256 constant PROPOSAL_CHANGE_QUEUE_TIMEOUT = 3;
    // uint256 constant PROPOSAL_CHANGE_SERVE_TIMEOUT = 4;
    // uint256 constant PROPOSAL_CHANGE_MAX_OUTSTANDING_PAYMENTS = 5;
    // uint256 constant PROPOSAL_CHANGE_IS_PERMISSIONED = 5;

    struct Dao {
        mapping(address => Member) members;
        mapping(uint256 => Proposal) proposals;
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
    event ProposalCreated(bytes32 daoId, uint256 proposalId, uint256 proposalType);
    event Voted(bytes32 daoId, address voter, uint256 proposalId, bool vote);
    event ProposalExecuted(bytes32 daoId, address voter, uint256 proposalId);

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


    // governance

    modifier onlyMember(bytes32 daoId) {
        require(daos[daoId].members[msg.sender].isMember, "Not a member");
        _;
    }

    function addMember(bytes32 daoId, address _member) public {
        if (daos[daoId].isPermissioned) {
            require(daos[daoId].members[msg.sender].isMember, "Not a member");
        }
        require(!daos[daoId].members[_member].isMember, "Already a member");
        daos[daoId].members[_member] = Member(_member, true);
        emit MemberAdded(daoId, _member);
    }

    function createProposal(bytes32 daoId, uint256 proposalType) public onlyMember(daoId) returns (uint256) {
        Dao storage dao = daos[daoId];
        uint256 proposalId = dao.numProposals++;
        Proposal storage newProposal = dao.proposals[proposalId];
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        emit ProposalCreated(daoId, proposalId, _description);
        return proposalId;
    }

    function vote(bytes32 daoId, uint256 _proposalId, bool _support) public onlyMember(daoId) {
        Proposal storage proposal = daos[daoId].proposals[_proposalId];
        require(!proposal.voted[msg.sender], "Already voted");
        proposal.voted[msg.sender] = true;

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(daoId, msg.sender, _proposalId, _support);
    }

}
