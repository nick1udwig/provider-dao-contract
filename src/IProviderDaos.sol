// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IProviderDaos {
    function getVotingThreshold(bytes32 daoId) external returns (uint256);
    function addMember(bytes32 daoId, uint256 proposalId, address newMember, bytes32 nodeId) external;
    function changeMember(bytes32 daoId, uint256 proposalId, address member, bool newIsMember, bool newIsProvider, bool newIsRouter) external;
    function changeParameters(bytes32 daoId, uint256 proposalId, uint256 newQueueResponseTimeoutSeconds, uint256 newServeTimeoutSeconds, uint256 newMaxOutstandingPayments) external;
    function changeIsPermissioned(bytes32 daoId, uint256 proposalId, bool newIsPermissioned) external;
}
