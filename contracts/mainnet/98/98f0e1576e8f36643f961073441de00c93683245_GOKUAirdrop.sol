/**
 *Submitted for verification at Etherscan.io on 2020-09-29
*/

/*
* Author : Christopher D.
*/

pragma solidity 0.5.17;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

interface IERC20 {
    function mint(address account, uint amount) external;
}

contract GOKUAirdrop {
    using SafeMath for uint256;

    mapping(address => uint256) public supplies;
    IERC20 public goku = IERC20(0x4E44FE174e934ff78A77BEe3C2b752fD1BEeFDEf); //need replace

    address public gov;

    constructor()
        public
    {
        gov = msg.sender;
    }

    modifier onlyGov()
    {
        require(msg.sender == gov, "require gov!");
        _;
    }

    function setAirdropSupply(address pool, uint256 initSupply)
        external
        onlyGov
    {
        supplies[pool] = initSupply;
    }

    function transferOwnership(address owner)
        external
        onlyGov
    {
        gov = owner;
    }

    function getRemainAirdrop(address pool)
        external
        view
        returns (uint256)
    {
        return supplies[pool];
    }

    function airdrop(uint256 value)
        external
    {
        require(supplies[msg.sender] > 0, "Unable to call!");
        require(value > 0, "Unable to airdrop 0!");
        require(supplies[msg.sender] >= value, "Unable to airdrop!");
        goku.mint(msg.sender, value);
        supplies[msg.sender] = supplies[msg.sender].sub(value);
    }

    function airdropAll()
        external
    {
        require(supplies[msg.sender] > 0, "Unable to call!");
        goku.mint(msg.sender, supplies[msg.sender]);
        supplies[msg.sender] = 0;
    }
}