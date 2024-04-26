// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IProviderDaos} from "./IProviderDaos.sol";

abstract contract Proposal {
    address public dao;
    bytes32 public daoId;
    uint256 public id;
    address public proposer;
    mapping(address => bool) public hasVoted;
    uint256 public yesVotes;
    uint256 public noVotes;
    //uint256 public votingThreshold;
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    ProposalStatus public status;

    constructor(address _dao, bytes32 _daoId, uint256 _id, address _proposer) {
        dao = _dao;
        daoId = _daoId;
        id = _id;
        proposer = _proposer;
        status = ProposalStatus.Pending;
    }

    function execute() virtual public;

    function checkStatus() public {
        uint256 votingThreshold = IProviderDaos(dao).getVotingThreshold(daoId);
        if (yesVotes >= votingThreshold) {
            status = ProposalStatus.Approved;
            execute();
        } else if (noVotes >= votingThreshold) {
            status = ProposalStatus.Rejected;
        }
    }

    function vote(bool approve) public {
        require(status == ProposalStatus.Pending, "Proposal must be Pending to vote");
        require(hasVoted[msg.sender] == false, "Voter has already voted");

        hasVoted[msg.sender] = true;
        if (approve) {
            yesVotes++;
        } else {
            noVotes++;
        }
        checkStatus();
    }
}

contract AddMemberProposal is Proposal {
    address public newMember;

    constructor(address _dao, bytes32 _daoId, uint256 _id, address _proposer, address _newMember) Proposal(_dao, _daoId, _id, _proposer) {
        newMember = _newMember;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IProviderDaos(dao).addMember(daoId, id, newMember);
    }
}

contract ChangeMemberProposal is Proposal {
    address public member;
    bool public newIsMember;
    bool public newIsProvider;
    bool public newIsRouter;

    constructor(address _dao, bytes32 _daoId, uint256 _id, address _proposer, address _member, bool _newIsMember, bool _newIsProvider, bool _newIsRouter) Proposal(_dao, _daoId, _id, _proposer) {
        member = _member;
        newIsMember = _newIsMember;
        newIsProvider = _newIsProvider;
        newIsRouter = _newIsRouter;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IProviderDaos(dao).changeMember(daoId, id, member, newIsMember, newIsProvider, newIsRouter);
    }
}

contract ChangeParametersProposal is Proposal {
    uint256 public newQueueResponseTimeoutSeconds;
    uint256 public newServeTimeoutSeconds;
    uint256 public newMaxOutstandingPayments;

    constructor(address _dao, bytes32 _daoId, uint256 _id, address _proposer, uint256 _newQueueResponseTimeoutSeconds, uint256 _newServeTimeoutSeconds, uint256 _newMaxOutstandingPayments) Proposal(_dao, _daoId, _id, _proposer) {
        newQueueResponseTimeoutSeconds = _newQueueResponseTimeoutSeconds;
        newServeTimeoutSeconds = _newServeTimeoutSeconds;
        newMaxOutstandingPayments = _newMaxOutstandingPayments;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IProviderDaos(dao).changeParameters(daoId, id, newQueueResponseTimeoutSeconds, newServeTimeoutSeconds, newMaxOutstandingPayments);
    }
}

contract ChangeIsPermissionedProposal is Proposal {
    bool public newIsPermissioned;

    constructor(address _dao, bytes32 _daoId, uint256 _id, address _proposer, bool _newIsPermissioned) Proposal(_dao, _daoId, _id, _proposer) {
        newIsPermissioned = _newIsPermissioned;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IProviderDaos(dao).changeIsPermissioned(daoId, id, newIsPermissioned);
    }
}
