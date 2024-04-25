// SPDX-License-Identifier: MIT
pragma solidity ^0.9.0;

import "./DaoInterface.sol";

abstract contract Proposal {
    address public dao;
    uint256 public id;
    address public proposer;
    mapping(address => bool) public hasVoted;
    uint256 public yesVotes;
    uint256 public noVotes;
    //uint256 public votingThreshold;
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    ProposalStatus public status;

    constructor(uint256 _id, address _proposer) {
        id = _id;
        proposer = _proposer;
        status = ProposalStatus.Pending;
    }

    function execute() virtual public;

    function checkStatus() public {
        memory votingThreshold = IDao(dao).getVotingThreshold();
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

    constructor(uint256 _id, address _proposer, address _newMember) {
        id = _id;
        proposer = _proposer;
        status = ProposalStatus.Pending;
        newMember = _newMember;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IDao(dao).addMember(newMember);
    }
}

contract ChangeMemberProposal is Proposal {
    address public member;
    bool newIsMember;
    bool newIsProvider;
    bool newIsRouter;

    constructor(uint256 _id, address _proposer, address _member, bool _newIsMember, bool _newIsProvider, bool _newIsRouter) {
        id = _id;
        proposer = _proposer;
        status = ProposalStatus.Pending;
        member = _member;
        newIsMember = _newIsMember;
        newIsProvider = _newIsProvider;
        newIsRouter = _newIsRouter;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IDao(dao).changeMember(member, newIsMember, newIsProvider, newIsRouter);
    }
}

contract ChangeParametersProposal is Proposal {
    uint256 public newQueueResponseTimeoutSeconds;
    uint256 public newServeTimeoutSeconds;
    uint256 public newMaxOutstandingPayments;

    constructor(uint256 _id, address _proposer, uint256 _newQueueResponseTimeoutSeconds, uint256 _newServeTimeoutSeconds, uint256 _newMaxOutstandingPayments) {
        id = _id;
        proposer = _proposer;
        status = ProposalStatus.Pending;
        newQueueResponseTimeoutSeconds = _newQueueResponseTimeoutSeconds;
        newServeTimeoutSeconds = _newServeTimeoutSeconds;
        newMaxOutstandingPayments = _newMaxOutstandingPayments;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IDao(dao).changeParameters(newQueueResponseTimeoutSeconds, newServeTimeoutSeconds, newMaxOutstandingPayments);
    }
}

contract ChangeIsPermissionedProposal is Proposal {
    bool public newIsPermissioned;

    constructor(uint256 _id, address _proposer, bool _newIsPermissioned) {
        id = _id;
        proposer = _proposer;
        status = ProposalStatus.Pending;
        newIsPermissioned = _newIsPermissioned;
    }

    function execute() override public {
        require(status == ProposalStatus.Approved, "Proposal must be Approved to execute");
        status = ProposalStatus.Executed;
        IDao(dao).changeIsPermissioned(newIsPermissioned);
    }
}
