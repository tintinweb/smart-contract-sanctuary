pragma solidity ^0.4.24;

contract F3DexternalSettings {
    function getLongExtra()
        public
        view
        returns(uint256)
    {
        return (0); // length of the very first ICO 
    }

    function getLongGap()
        public
        view
        returns(uint256)
    {
        return (24 hours); // length of ICO phase
    }
}

