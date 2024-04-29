// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import "../src/ProviderDaos.sol";

contract ProviderDaosTest is Test {
    ProviderDaos providerDaos;
    address deployer;
    bytes32 daoId;
    uint256 proposalId;

    function setUp() public {
        deployer = address(this);
        providerDaos = new ProviderDaos();
        daoId = providerDaos.createDao(bytes32("foo.os"));  // Deployer is automatically a member
    }

    // Test creating a DAO
    function testCreateDao() public view {
        assertTrue(providerDaos.numDaos() == 1, "Should have exactly one DAO");
    }

    // Test adding a member
    function testAddMember() public {
        address newMember = address(0xBEEF);
        proposalId = providerDaos.createProposalAddMember(daoId, newMember, bytes32("bar.os"));
        providerDaos.vote(daoId, proposalId, true);

        // Simulate advancing time to finalize the proposal (if necessary, based on the logic)
        // skip(1 days);

        (, bool isMember, , ) = providerDaos.getMemberInfo(daoId, newMember);
        assertTrue(isMember, "New member should be added.");
    }

    // Test member change proposal
    function testChangeMember() public {
        //address member = address(0xBEEF);
        address member = address(this);
        bool newIsMember = false;
        bool newIsProvider = true;
        bool newIsRouter = false;
        proposalId = providerDaos.createProposalChangeMember(daoId, member, newIsMember, newIsProvider, newIsRouter);
        providerDaos.vote(daoId, proposalId, true);

        (, bool isMember, , ) = providerDaos.getMemberInfo(daoId, member);
        assertFalse(isMember, "Member status should be changed.");
    }

    // Test changing DAO parameters
    function testChangeParameters() public {
        uint256 newQueueResponseTimeout = 30;
        uint256 newServeTimeout = 60;
        uint256 newMaxPayments = 5;
        proposalId = providerDaos.createProposalChangeParameters(daoId, newQueueResponseTimeout, newServeTimeout, newMaxPayments);
        providerDaos.vote(daoId, proposalId, true);

        assertEq(providerDaos.getQueueResponseTimeoutSeconds(daoId), newQueueResponseTimeout, "Queue response timeout should be updated.");
        assertEq(providerDaos.getServeTimeoutSeconds(daoId), newServeTimeout, "Serve timeout should be updated.");
        assertEq(providerDaos.getMaxOutstandingPayments(daoId), newMaxPayments, "Max outstanding payments should be updated.");
    }

    // Test permission changes
    function testChangeIsPermissioned() public {
        bool newIsPermissioned = false;
        proposalId = providerDaos.createProposalChangeIsPermissioned(daoId, newIsPermissioned);
        providerDaos.vote(daoId, proposalId, true);

        assertFalse(providerDaos.getIsPermissioned(daoId), "DAO should not be permissioned anymore.");
    }
}
