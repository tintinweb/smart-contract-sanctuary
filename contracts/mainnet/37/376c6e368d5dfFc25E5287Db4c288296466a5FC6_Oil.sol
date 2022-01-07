/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Inspired by Solmate: https://github.com/Rari-Capital/solmate
/// Developed by 0xBasset

// import "hardhat/console.sol";

contract Oil {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    address public impl_;
    address public ruler;
    address public treasury;
    address public uniPair;
    address public weth;

    uint256 public totalSupply;
    uint256 public startingTime;
    uint256 public baseTax;
    uint256 public minSwap;

    bool public paused;
    bool public swapping;

    ERC721Like public habibi;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    mapping(uint256 => uint256) public claims;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "OIL";
    }

    function symbol() external pure returns (string memory) {
        return "OIL";
    }
    
    function decimals() external pure returns (uint8) {
        return 18;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    
    function initialize(address habibi_,address treasury_, address uniPair_, address weth_) external { 
        require(msg.sender == ruler);
       
        ruler    = msg.sender;  
        treasury = treasury_;
        uniPair  = uniPair_;
        weth     = weth_;

        startingTime = 1640707200;
        baseTax      = 10_000; // 10% in basis point
        habibi       = ERC721Like(habibi_);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);

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

        _transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              CLAIM
    //////////////////////////////////////////////////////////////*/

    function claim(uint256 id_) public {
        require(!paused || msg.sender == ruler, "claims are paused");

        address owner = habibi.ownerOf(id_);
        require(owner != address(0), "token does not exist");

        uint256 amount = _claimable(id_, owner);
        
        claims[id_] = block.timestamp;

        _mint(owner, amount);
    }

    function claimMany(uint256[] calldata ids_) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            claim(ids_[i]);
        }
    }

    function claimable(uint256 id) public view returns (uint256) {
        return _claimable(id, habibi.ownerOf(id));
    }

    function _claimable(uint256 id_, address owner_) internal view returns (uint256 amount) {
        uint256 lastClaim = claims[id_];
        uint256 diff      = block.timestamp - (lastClaim == 0 ? startingTime : lastClaim);
        uint256 balance   = habibi.balanceOf(owner_);
        uint256 base      = diff * 1000 ether / 1 days;
        
        amount    = base + ((_getBonusPct(id_, balance) * base * 1e16) / 1e18);
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

    function _transfer(address from, address to, uint256 value) internal {
        
        uint256 tax = 0;
        if ((to == uniPair || from == uniPair) && !swapping && balanceOf[uniPair] != 0) {
            tax = value * 10_000 / 100_000;
            
            if (to == uniPair) {
                swapping = true;
                _doSwap(tax);
                swapping = false;
            } else {
                totalSupply -= tax;
                emit Transfer(uniPair, address(0), tax);
            }
        }

        balanceOf[from] -= value;
        balanceOf[to]   += value - tax;

        emit Transfer(from, to, value - tax);
    }

    function _doSwap(uint256 amt) internal {
        UniPairLike pair = UniPairLike(uniPair);
        
        (uint256 amount0Out, uint256 amount1Out) = (0,0);

        uint256 wethBal    = ERC721Like(weth).balanceOf(uniPair);
        uint256 amtWithFee = amt * 997;
        uint256 amtOut     = (wethBal * amtWithFee) / (balanceOf[uniPair] * 1000 + amtWithFee);

        if (amtOut < minSwap) {
            // If it's too little amt, we just burn it
            totalSupply -= amt;
            emit Transfer(uniPair, address(0), amt);
            return;
        }

        if (pair.token0() == address(this)) {
            amount1Out = amtOut;
        } else {
            amount0Out = amtOut;
        }

        balanceOf[uniPair] += amt;
        pair.swap(amount0Out, amount1Out, treasury, new bytes(0));
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
        if ( id_ == 2137) return true;  
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

}

interface ERC721Like {
    function balanceOf(address holder_) external view returns(uint256);
    function ownerOf(uint256 id_) external view returns(address);
}

interface UniPairLike {
    function token0() external returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}