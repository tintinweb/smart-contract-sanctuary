pragma solidity ^0.4.11;

library Math {
    /// @dev Returns whether an add operation causes an overflow
    /// @param a First addend
    /// @param b Second addend
    /// @return Did no overflow occur?
    function safeToAdd(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a + b >= a;
    }

    /// @dev Returns whether a subtraction operation causes an underflow
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Did no underflow occur?
    function safeToSub(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return a >= b;
    }

    /// @dev Returns whether a multiply operation causes an overflow
    /// @param a First factor
    /// @param b Second factor
    /// @return Did no overflow occur?
    function safeToMul(uint a, uint b)
        public
        constant
        returns (bool)
    {
        return b == 0 || a * b / b == a;
    }

    /// @dev Returns sum if no overflow occurred
    /// @param a First addend
    /// @param b Second addend
    /// @return Sum
    function add(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToAdd(a, b));
        return a + b;
    }

    /// @dev Returns difference if no overflow occurred
    /// @param a Minuend
    /// @param b Subtrahend
    /// @return Difference
    function sub(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToSub(a, b));
        return a - b;
    }

    /// @dev Returns product if no overflow occurred
    /// @param a First factor
    /// @param b Second factor
    /// @return Product
    function mul(uint a, uint b)
        public
        constant
        returns (uint)
    {
        require(safeToMul(a, b));
        return a * b;
    }
}