/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// File: contracts\utils\Interfaces.sol

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0-or-later

contract Interfaces { }

//for the buoy ERC20
interface Buoy {
    function mineMint(uint, address) external;
    function lotteryMint(uint, address) external;
}

//for the smart pool
interface SPool {
    function setController(address newOwner) external;
    function setPublicSwap(bool publicSwap) external;
    function removeToken(address token) external;
    function changeOwner(address newOwner) external;
    function changeWeight(uint[] calldata) external;
    function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut) external;
    function applyAddToken() external;
    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    ) external;
    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    ) external;
}
    
//for uniswap deposit
interface UniswapInterface {
    function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

//for the address interface
interface  IAddressIndex {
    function setBuoy(address newaddress) external;
    function getBuoy() external view returns(address);
    function setUniswap(address newaddress) external;
    function getUniswap() external view returns(address);
    function setBalancerPool(address newaddress) external;
    function getBalancerPool() external view returns(address);
    function setSmartPool(address newaddress) external;
    function getSmartPool() external view returns(address);
    function setXBuoy(address newaddress) external;
    function getXBuoy() external view returns(address);
    function setProxy (address newaddress) external;
    function getProxy() external view returns(address);
    function setMine(address newaddress) external;
    function getMine() external view returns(address);
    function setVotingBooth(address newaddress) external;
    function getVotingBooth() external view returns(address);
    function setLottery(address newaddress) external;
    function getLottery() external view returns(address);
}

//for the xbuoy NFT
interface IBuoy {
    function approve(address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
    function burn(uint _id) external;
    function setBuoyMine(address newAddress) external;
    function safeTransferfrom(address from, address to, uint256 tokenId) external;
    function setNFT(uint,uint,uint) external;
    function killNFT(uint) external;
    function viewNFT(uint id) external view returns(
        bool active,
        uint contributed, 
        uint allotment, 
        uint rewards, 
        uint payouts, 
        uint nextClaim,
        address platform);
    function craftNFT(
        address sender, 
        uint contributed, 
        uint allotment, 
        uint rewards, 
        uint payouts, 
        uint nextClaim,
        address platform
        ) external;
}

//for the liquidity staking mine
interface Mine {
    function setStakingActive(bool active) external;
    function setSwapingActive(bool active) external;
    function changeStakingMax(uint[] calldata newMax) external;
    function changeStakingShare(uint[] calldata newShare) external;
}

interface IProxy {
    function _setSwapFee(uint _swapFee) external; 
    function _setController(address x) external; 
    function _updateWeights(uint[] calldata x) external; 
    function _setSwapingActive(bool active) external;
}

interface ILottery {
    function setShare(uint[] calldata array) external;
    function setDrawLength(uint) external;
    function setIncrementing(uint uintArray, bool boolArray) external;
}

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\balancer-labs\configurable-rights-pool\contracts\IBFactory.sol


pragma solidity ^0.8.0;

interface IBPool {
    function rebind(address token, uint balance, uint denorm) external;
    function setSwapFee(uint swapFee) external;
    function setPublicSwap(bool publicSwap) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;
    function isBound(address token) external view returns(bool);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
    function getSwapFee() external view returns (uint);
    function isPublicSwap() external view returns (bool);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);
    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint);
 
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint poolAmountIn);

    function getCurrentTokens()
        external view
        returns (address[] memory tokens);
}

interface IBFactory {
    function newBPool() external returns (IBPool);
    function setBLabs(address b) external;
    function collect(IBPool pool) external;
    function isBPool(address b) external view returns (bool);
    function getBLabs() external view returns (address);
}

// File: contracts\Proxy.sol

pragma solidity ^0.8.0;




contract Proxy {

    /*
    testing distrubuted methods of add remove tokens

    WORKING:
    -beginAddToken
    -when contract has enough coin
    -finalizeAddToken

    
    */

    uint counter;
    address public owner; 
    address index;
    bool lock;

    
    IAddressIndex addressIndex;

    mapping(address => uint[]) public addressToIndex;
    mapping(address => uint[]) userShares;
    mapping(uint => AddToken) addTokenMap;
    mapping(uint => RemoveToken) removeTokenMap;

    struct RemoveToken {
        mapping(address => bool) userContributed;
        mapping(address => uint) userAmountIn;
        mapping(address => uint) userShare;
        address token;
        uint leftovers;
        uint returnOnSwap;
        uint amountLPIn;
        bool active;
        bool withdrawable;
    }

    struct AddToken {
        mapping(address => bool) userContributed;
        mapping(address => uint) userAmountIn;
        mapping(address => uint) userShare;
        address token;
        uint leftovers;
        uint weight;
        uint balance;
        uint returnOnSwap;
        uint amountTokenIn;
        bool active;
        bool withdrawable;
    }

    event tokenAdded(uint, address);
    event tokenRemoved(uint, address);

    constructor(address x) {
        owner = msg.sender;
        index = x;
        addressIndex = IAddressIndex(index);
    }

    function beginRemoveToken(address tokenToRemove) public {
        require(lock == false);
        address pool = addressIndex.getSmartPool();
        IERC20 lp = IERC20(pool);
        IERC20 token = IERC20(tokenToRemove);
        removeTokenMap[counter].token = tokenToRemove;
        removeTokenMap[counter].active = true;
        removeTokenMap[counter].leftovers = lp.balanceOf(address(this));
        removeTokenMap[counter].returnOnSwap = token.balanceOf(address(this));
        lock = true;
    }

    function finalizeRemoveToken() public  {
        require(removeTokenMap[counter].active = true);
        address pool = addressIndex.getSmartPool();
        SPool spool = SPool(addressIndex.getSmartPool());
        //require removetmap[counter].tokens = ?? fail if too low. total LP supply /
        IERC20 lp = IERC20(pool);
        IERC20 token = IERC20(addTokenMap[counter].token);
        removeTokenMap[counter].leftovers = (lp.balanceOf(address(this)) - removeTokenMap[counter].leftovers);
        removeTokenMap[counter].returnOnSwap = (token.balanceOf(address(this)) - removeTokenMap[counter].returnOnSwap);
        spool.removeToken(removeTokenMap[counter].token);  
        emit tokenRemoved(counter,addTokenMap[counter].token);
        counter++;
    }

    function beginAddToken(address token, uint balance, uint weight) public  {
        //Proposal delegation amount
        require(lock == false);
        address pool = addressIndex.getSmartPool();
        SPool spool = SPool(addressIndex.getSmartPool());
        addTokenMap[counter].active = true;
        addTokenMap[counter].token = token;
        addTokenMap[counter].balance = balance;
        addTokenMap[counter].weight = weight;
        IERC20 erc20 = IERC20(token);
        erc20.approve(pool,type(uint).max);
        spool.commitAddToken(token, balance, weight);
        lock = true;
    }

    function finalizeAddToken() public {
        require(addTokenMap[counter].amountTokenIn >= addTokenMap[counter].balance);
        address pool = addressIndex.getSmartPool();
        SPool spool = SPool(addressIndex.getSmartPool());
        IERC20 lp = IERC20(pool);
        IERC20 token = IERC20(addTokenMap[counter].token);
        spool.applyAddToken();
        addTokenMap[counter].leftovers = token.balanceOf(address(this));
        addTokenMap[counter].returnOnSwap = lp.balanceOf(address(this));
        addTokenMap[counter].active = false;
        addTokenMap[counter].withdrawable = true;
        emit tokenAdded(counter,addTokenMap[counter].token);
        counter++;
        lock = false;
    }

    //type 0 = added token, type 1 = removed token
    function claimTokenShare(uint kind, uint mapIndex) public {
        uint lpShare;
        uint tokenShare;
        address pool = addressIndex.getSmartPool();
        IERC20 token;
        IERC20 lp;
        if(kind == 0) {
            require(addTokenMap[mapIndex].withdrawable == true, 'Not yet processed');
            uint share = (addTokenMap[mapIndex].userAmountIn[msg.sender] * 10000) / addTokenMap[mapIndex].amountTokenIn; // turns percentage into integer up to the hundreths (1.2% = 120)
            tokenShare = addTokenMap[mapIndex].leftovers * share / 10000; // takes total tokens to be distributed and finds the amount owed (may round dust up to 99 wei)
            lpShare = addTokenMap[mapIndex].returnOnSwap * share / 10000; // takes total tokens to be distributed and finds the amount owed (may round dust up to 99 wei)
            lp = IERC20(pool);
            token = IERC20(addTokenMap[mapIndex].token);
        } else if(kind == 1) {
            require(removeTokenMap[mapIndex].withdrawable == true, 'Not yet processed');
            uint share = (removeTokenMap[mapIndex].userAmountIn[msg.sender] * 10000) / addTokenMap[mapIndex].amountTokenIn; // turns percentage into integer up to the hundreths (1.2% = 120)
            tokenShare = removeTokenMap[mapIndex].returnOnSwap * share / 10000; // takes total tokens to be distributed and finds the amount owed (may round dust up to 99 wei)
            lpShare = removeTokenMap[mapIndex].leftovers * share / 10000; // takes total tokens to be distributed and finds the amount owed (may round dust up to 99 wei)
            lp = IERC20(pool);
            token = IERC20(removeTokenMap[mapIndex].token);
        }
        lp.transfer(msg.sender, lpShare);
        token.transfer(msg.sender, tokenShare);
        removeMapping(mapIndex);
    }

    function setShare() public returns(uint) {
        return(addTokenMap[counter].userShare[msg.sender] = addTokenMap[counter].userAmountIn[msg.sender] / addTokenMap[counter].amountTokenIn);
    }

    function contributeAddToken(uint amount) public {
        require(amount + addTokenMap[counter].amountTokenIn <= (addTokenMap[counter].balance * 101) / 100, 'Contribution too high'); //gives 1% buffer room to make sure balance is easy to hit
        require(addTokenMap[counter].active == true, 'No Active add token proposal');
        require(amount >= 10000, 'Contribution too small');
        IERC20 erc20 = IERC20(addTokenMap[counter].token);
        erc20.transferFrom(msg.sender, address(this), amount);
        addTokenMap[counter].amountTokenIn = addTokenMap[counter].amountTokenIn + amount;
        addTokenMap[counter].userAmountIn[msg.sender] = addTokenMap[counter].userAmountIn[msg.sender] + amount;
        if(addTokenMap[counter].userContributed[msg.sender] == false) {
            addTokenMap[counter].userContributed[msg.sender] = true;
            userShares[msg.sender].push(counter);
        }
    }
    
    function contributeRemoveToken(uint amount) public {
        require(removeTokenMap[counter].active == true, 'No Active remove token proposal');
        require(amount >= 10000, 'Contribution too small');
        IERC20 erc20 = IERC20(addressIndex.getSmartPool());
        erc20.transferFrom(msg.sender, address(this), amount);
        removeTokenMap[counter].amountLPIn = removeTokenMap[counter].amountLPIn + amount;
        removeTokenMap[counter].userAmountIn[msg.sender] = addTokenMap[counter].userAmountIn[msg.sender] + amount;
        if(removeTokenMap[counter].userContributed[msg.sender] == false) {
            removeTokenMap[counter].userContributed[msg.sender] = true;
            userShares[msg.sender].push(counter);
        }
    }

    //0 = added, 1 = removed
    function removeMapping(uint mapIndex) public {
        uint arrayLength = addressToIndex[msg.sender].length;
        uint nonce;
        while(nonce > arrayLength) {
            if(addressToIndex[msg.sender][nonce] == mapIndex) {
                delete addressToIndex[msg.sender][nonce];
                nonce = arrayLength;
            }
            nonce++;
        }
    }

    function commitAddToken(address token, uint balance, uint weight) public  {
        address pool = addressIndex.getSmartPool();
        SPool spool = SPool(addressIndex.getSmartPool());
        IERC20 erc20 = IERC20(token);
        erc20.approve(pool,type(uint).max);
        spool.commitAddToken(token, balance, weight);
    }

    function applyAddToken() public  {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.applyAddToken();  
    }

    //2
    function _setSwapFee(uint _swapFee) public {
        IBPool ibpool = IBPool(addressIndex.getSmartPool());
        ibpool.setSwapFee(_swapFee);
    }

    //5
    function _setController(address x) public {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.setController(x);
    }

    //7
    function _updateWeights(uint[] calldata x) public {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.updateWeightsGradually(x, block.number, block.number + 3 days);
    }

    //10
    function _setSwapingActive(bool active) public {
        SPool spool = SPool(addressIndex.getSmartPool());
        spool.setPublicSwap(active);
    }

    function withdrawToken(address token) public {
        IERC20 erc20 = IERC20(token);
        uint balance = erc20.balanceOf(address(this));
        erc20.transfer(owner, balance);
    }

}