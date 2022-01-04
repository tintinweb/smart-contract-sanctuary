/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Inspired by Solmate: https://github.com/Rari-Capital/solmate
/// Developed by 0xBasset

contract Oil {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    string public constant name     = "OIL";
    string public constant symbol   = "OIL";
    uint8  public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256    public totalSupply;
    uint256    public startingTime;
    address    public ruler;
    bool       public paused;
    ERC721Like public habibi;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    mapping(uint256 => uint256) public claims;


    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    constructor() { 
        ruler        = msg.sender;
        startingTime = 1640707200;
        paused       = true;
        habibi       = ERC721Like(0x98a0227E99E7AF0f1f0D51746211a245c3B859c2);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              CLAIM
    //////////////////////////////////////////////////////////////*/

    function claim(uint256 id_) public {
        require(!paused, "claims are paused");
        address owner = habibi.ownerOf(id_);

        uint256 lastClaim = claims[id_];
        uint256 diff      = block.timestamp - (lastClaim == 0 ? startingTime : lastClaim);
        uint256 balance   = habibi.balanceOf(owner);
        uint256 base      = diff * 1000 ether / 1 days;
        uint256 amount    = base + ((_getBonusPct(id_, balance) * base * 1e16) / 1e18);
        
        claims[id_] = block.timestamp;

        _mint(owner, amount);
    }

    function claimMany(uint256[] calldata ids_) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            claim(ids_[i]);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            OIL PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter, bool status) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setRuler(address ruler_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        ruler = ruler_;
    }

    function setPaused(bool paused_) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        paused = paused_;
    }

    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _getBonusPct(uint256 id_, uint256 balance) internal pure returns (uint256 bonus) {
        if (_isAnimated(id_)) return 500;

        if (balance < 5) return 0;
        if (balance < 10) return 15;
        if (balance < 20) return 25;
        return 35;
    }

    function _isAnimated(uint256 id_) internal pure returns(bool animated) {
        if ( id_ == 40)   return true;
        if ( id_ == 108)  return true;
        if ( id_ == 169)  return true;
        if ( id_ == 191)  return true;
        if ( id_ == 246)  return true;
        if ( id_ == 257)  return true;
        if ( id_ == 319)  return true;
        if ( id_ == 386)  return true;
        if ( id_ == 496)  return true;
        if ( id_ == 562)  return true;
        if ( id_ == 637)  return true;
        if ( id_ == 692)  return true;
        if ( id_ == 832)  return true;
        if ( id_ == 942)  return true;
        if ( id_ == 943)  return true;
        if ( id_ == 957)  return true;
        if ( id_ == 1100) return true;
        if ( id_ == 1108) return true;
        if ( id_ == 1169) return true;
        if ( id_ == 1178) return true;
        if ( id_ == 1627) return true;
        if ( id_ == 1706) return true;
        if ( id_ == 1843) return true;
        if ( id_ == 1884) return true;
        if ( id_ == 2158) return true;
        if ( id_ == 2165) return true;
        if ( id_ == 2214) return true;
        if ( id_ == 2232) return true;
        if ( id_ == 2238) return true;
        if ( id_ == 2508) return true;
        if ( id_ == 2629) return true;
        if ( id_ == 2863) return true;
        if ( id_ == 3055) return true;
        if ( id_ == 3073) return true;
        if ( id_ == 3280) return true;
        if ( id_ == 3297) return true;
        if ( id_ == 3322) return true;
        if ( id_ == 3327) return true;
        if ( id_ == 3361) return true;
        if ( id_ == 3411) return true;
        if ( id_ == 3605) return true;
        if ( id_ == 3639) return true;
        if ( id_ == 3774) return true;
        if ( id_ == 4250) return true;
        if ( id_ == 4267) return true;
        if ( id_ == 4302) return true;
        if ( id_ == 4362) return true;
        if ( id_ == 4382) return true;
        if ( id_ == 4397) return true;
        if ( id_ == 4675) return true;
        if ( id_ == 4707) return true;
        if ( id_ == 4863) return true;
        return false;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

interface ERC721Like {
    function balanceOf(address holder_) external view returns(uint256);
    function ownerOf(uint256 id_) external view returns(address);
}