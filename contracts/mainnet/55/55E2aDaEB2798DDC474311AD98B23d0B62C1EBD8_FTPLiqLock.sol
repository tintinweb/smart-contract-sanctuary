/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ownable {
    address private m_Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        m_Owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return m_Owner;
    }
    
    function transferOwnership(address _address) public virtual {
        require(msg.sender == m_Owner);
        m_Owner = _address;
        emit OwnershipTransferred(msg.sender, _address);
    }                                                                                        
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface UniFactory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface UniV2Pair { 
    function balanceOf(address _address) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function token0() external returns (address);
    function token1() external returns (address);
}

contract FTPLiqLock is Ownable {
    using SafeMath for uint256;
    
    UniFactory private Factory;

    address private m_WebThree;
    address private m_Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    mapping (address => bool) private m_Locked;
    mapping (address => uint256) private m_PairRelease;
    mapping (address => address) private m_PayoutAddress;
    
    event Lock (address Pair, address Token1, address Token2, address Payout);
    event SetBurn (address Pair);

    constructor() {
        Factory = UniFactory(m_Factory);
    }

    function setWebThree(address _address) external {
        require(msg.sender == owner() || msg.sender == m_WebThree);
        m_WebThree = _address;
    }

    function lockTokens(address _uniPair, uint256 _epoch, address _tokenPayout) external {
        require(Factory.getPair(UniV2Pair(_uniPair).token0(), UniV2Pair(_uniPair).token1()) == _uniPair, "Please only deposit UniV2 tokens");
        require(!m_Locked[_uniPair], "Liquidity already locked before");
        require(UniV2Pair(_uniPair).balanceOf(msg.sender).mul(100).div(UniV2Pair(_uniPair).totalSupply()) >= 98, "Caller must hold all UniV2 tokens");
        m_PairRelease[_uniPair] = _epoch;
        m_PayoutAddress[_uniPair] = _tokenPayout;
        UniV2Pair(_uniPair).transferFrom(address(msg.sender), address(this), UniV2Pair(_uniPair).balanceOf(msg.sender));
        m_Locked[_uniPair] = true;
        
        emit Lock(_uniPair, UniV2Pair(_uniPair).token0(), UniV2Pair(_uniPair).token1(), m_PayoutAddress[_uniPair]);
    }
    
    function releaseTokens(address _uniPair) external {
        require(msg.sender == m_WebThree || msg.sender == m_PayoutAddress[_uniPair]);
        require(m_Locked[_uniPair], "No liquidity locked currently");
        require(UniV2Pair(_uniPair).balanceOf(address(this)) > 0, "No tokens to release");
        require(block.timestamp > m_PairRelease[_uniPair], "Lock expiration not reached");

        UniV2Pair(_uniPair).approve(address(this), UniV2Pair(_uniPair).balanceOf(address(this)));
        UniV2Pair(_uniPair).transfer(m_PayoutAddress[_uniPair], UniV2Pair(_uniPair).balanceOf(address(this)));
    }
    
    function setBurn(address _uniPair) external {
        require(msg.sender == m_PayoutAddress[_uniPair]);
        m_PayoutAddress[_uniPair] = address(0);
        
        emit SetBurn(_uniPair);
    }

    function getLockedTokens(address _uniPair) external view returns (bool Locked, uint256 ReleaseDate, address PayoutAddress) {
        if(block.timestamp < m_PairRelease[_uniPair])
            return (true, m_PairRelease[_uniPair], m_PayoutAddress[_uniPair]);
        return (false, m_PairRelease[_uniPair], m_PayoutAddress[_uniPair]);
    }
}