/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract Function {
    //  Functions can return multiple values.
    function returnMany()
    public 
    pure
    returns (
        uint,
        bool,
        uint
    )
    {
        return (1, true, 2);
    }

    //  Return values can be named
    function named()
    public
    pure
    returns (
        uint x,
        bool b,
        uint y
    )
    {
        return (1, true, 2);
    }

    // return values can be assigned to their name
    // the return statement can be omitted
    function assigned()
    public
    pure
    returns (
        uint x,
        bool b,
        uint y
    )
    {
        x = 1;
        b = true;
        y = 2;
    }

    //  cannot use map for input or output
    //  can use array for input
    function arrayInput(uint[] memory _arr) public {}

    //  can use array for output
    uint[] public arr;
    function arrayOutput() public view returns(uint[] memory) {
        return arr;
    }
}