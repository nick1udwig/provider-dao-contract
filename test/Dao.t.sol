// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ProviderDaos} from "../src/ProviderDaos.sol";

contract DaoTest is Test {
    ProviderDaos public daos;

    function setUp() public {
        daos = new ProviderDaos();
    }

    //function test_Increment() public {
    //    counter.increment();
    //    assertEq(counter.number(), 1);
    //}

    //function testFuzz_SetNumber(uint256 x) public {
    //    counter.setNumber(x);
    //    assertEq(counter.number(), x);
    //}
}
