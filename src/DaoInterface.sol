// SPDX-License-Identifier: MIT
pragma solidity ^0.9.0;

interface IDao {
    function getVotingThreshold() external returns uint256;
    function addMember(address newMember) external;
    function changeMember(address member, bool newIsMember, bool newIsProvider, bool newIsRouter) external;
    function changeParameters(uint256 newQueueResponseTimeoutSeconds, uint256 newServeTimeoutSeconds, uint256 newMaxOutstandingPayments) external;
    function changeIsPermissioned(bool newIsPermissioned) external;
}
