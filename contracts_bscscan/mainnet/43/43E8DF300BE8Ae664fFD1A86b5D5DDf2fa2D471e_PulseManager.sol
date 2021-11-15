// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;
import "./IPulseManager.sol";
import "../openzeppelin/contracts/token/IToken.sol";
import "../openzeppelin/contracts/libraries/Ownable.sol";
import "../openzeppelin/contracts/libraries/SafeMath.sol";
import "../openzeppelin/contracts/token/IERC20.sol";
import "../pancakeswap/interfaces/IPancakeRouter02.sol";
import "../pancakeswap/interfaces/IPancakeFactory.sol";
import "../pancakeswap/interfaces/IPancakePair.sol";

contract PulseManager is IPulseManager, Ownable {
    using SafeMath for uint256;

    uint256 private creationTime = 0;
    uint256 public tokenPrice = 100000000000000000;

    bool public publicSalePaused = true;
    uint256 public publicSaleMintedTokens = 0;

    uint256 private tokensMintedByOwnerFromHalf = 1000000000;
    uint256 private periodicMintedTokens = 0;

    address public pulseTokenAddress;
    IERC20 private pulseToken = IERC20(0x00);
    IPancakeRouter02 private pancakeSwapRouter;
    IPancakeFactory private factory;
    mapping(address => bool) public isTokenInReviveBasket;

    address private pancakeSwapRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    struct reviveBasketToken {
        address tokenAddress;
        uint256 weight;
    }

    reviveBasketToken[] public reviveBasketTokens;
    uint256 private reviveBasketWeight = 0;

    event SetTokenAddress(address indexed user, address _tokenAddress);
    event SetTokenPrice(address indexed user, uint256 _tokenPrice);
    event MintHalfByOwner(address indexed user, address _to, uint256 _amount);
    event InitPublicSale(address indexed user);
    event PausePublicSale(address indexed user);
    event PeriodicMint(address indexed user, uint256 _amountToBeMinted);
    event AddToken(address indexed user, address _tokenAddress, uint256 _tokenWeight);
    event RemoveToken(address indexed user, address _tokenAddress);
    event RedeemLpTokens(address indexed user, address _tokenAddress, uint256 _lpTokens);
    event RedeemLpTokensPulse(address indexed user, uint256 _lpTokens);
    event BurnRemainingBNB(address indexed user, uint256 _amount);
    event BurnRemainingPulse(address indexed user, uint256 _amount);

    constructor(address _pancakeSwapRouterAddress) public {
        creationTime = block.timestamp;
        pancakeSwapRouterAddress = _pancakeSwapRouterAddress;
        pancakeSwapRouter = IPancakeRouter02(
            _pancakeSwapRouterAddress
        );
        factory = IPancakeFactory(pancakeSwapRouter.factory());
    }

    //used to set the address of the PULSE token
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        pulseToken = IERC20(_tokenAddress);
        pulseTokenAddress = _tokenAddress;
        emit SetTokenAddress(_msgSender(), _tokenAddress);
    }

    //used to set the price of the PULSE token
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
        emit SetTokenPrice(_msgSender(), _tokenPrice);
    }

    //converts percentage to amount from 1000000000
    function _percentageToAmountMintedToken(uint256 _percentage)
        private
        pure
        returns (uint256)
    {
        //maximum supply divided by 100
        uint256 maximumSupply = 10**16;
        maximumSupply = maximumSupply.mul(_percentage);
        return maximumSupply;
    }

    //used to mint half of the total tokens to the owner
    function mintHalfByOwner(address _to, uint256 _amount) external onlyOwner {
        require(
            _percentageToAmountMintedToken(50)  >= tokensMintedByOwnerFromHalf.add(_amount),
            "Mint: you can mint a maximum amount of 50% from total amount of tokens"
        );
        pulseToken.mint(_to, _amount);
        tokensMintedByOwnerFromHalf = tokensMintedByOwnerFromHalf.add(_amount);
        emit MintHalfByOwner(_msgSender(), _to, _amount);
    }

    //used to make publicSale function callable
    function initPublicSale() external onlyOwner {
        publicSalePaused = false;
        emit InitPublicSale(_msgSender());
    }

    //used to make publicSale function uncallable
    function pausePublicSale() external onlyOwner {
        publicSalePaused = true;
        emit PausePublicSale(_msgSender());
    }

    //used to buy tokens with BNB
    function publicSale() external payable {
        uint256 bnb = msg.value;
        uint256 pulseToBeBought = bnb.mul(10**9) / tokenPrice;
        uint256 maxMintablePs = _percentageToAmountMintedToken(10);
        require(
            publicSalePaused == false,
            "Public sale: public sale is paused or it has stopped"
        );
        require(
            publicSaleMintedTokens + pulseToBeBought <= maxMintablePs,
            "Public sale: you need to buy less Pulse"
        );
        payable(owner()).transfer(msg.value);
        pulseToken.mint(_msgSender(), pulseToBeBought);
        publicSaleMintedTokens = publicSaleMintedTokens.add(pulseToBeBought);
    }

    //used to redeem a specific amount of tokens after a period of months established below
    //if the max mintable amount of tokens is not claimed at the specified time, the remaining
    //amount will be able to the next reward so the owner does not need to claim all the tokens in one trance
    function periodicMint(uint256 _amountToBeMinted) external onlyOwner {
        require(
            _amountToBeMinted > 0,
            "Periodic mint: amount to be minted should be greater than 0"
        );
        uint256 month = 30 days;
        //stores the max amount of tokens that the owner can mint now
        uint256 canMint = 0;
        //used to store the max amount of tokens to be minted, for each reward
        uint256 amountLimit = 0;

        //1: 5% after 6 months
        if (creationTime + month.mul(6) <= block.timestamp) {
            amountLimit = _percentageToAmountMintedToken(5);
            //calculate the remaining amount that can be minted from this reward
            if (periodicMintedTokens < amountLimit) {
                canMint = canMint.add(amountLimit.sub(periodicMintedTokens));
            }
        }
        //2: 10% after 12 months
        if (creationTime + month.mul(12) <= block.timestamp) {
            amountLimit = _percentageToAmountMintedToken(10);
            //calculate the remaining amount that can be minted from this reward
            if (periodicMintedTokens < amountLimit) {
                canMint = canMint.add(amountLimit.sub(periodicMintedTokens));
            }
        }
        //3: 10% after 18 months
        if (creationTime + month.mul(18) <= block.timestamp) {
            amountLimit = _percentageToAmountMintedToken(10);
            //calculate the remaining amount that can be minted from this reward
            if (periodicMintedTokens < amountLimit) {
                canMint = canMint.add(amountLimit.sub(periodicMintedTokens));
            }
        }
        //4: 15% after 24 months
        if (creationTime + month.mul(24) <= block.timestamp) {
            amountLimit = _percentageToAmountMintedToken(15);
            //calculate the remaining amount that can be minted from this reward
            if (periodicMintedTokens < amountLimit) {
                canMint = canMint.add(amountLimit.sub(periodicMintedTokens));
            }
        }
        require(
            canMint >= _amountToBeMinted,
            "Pulse: you need to mint less tokens"
        );
        pulseToken.mint(_msgSender(), _amountToBeMinted);
        periodicMintedTokens = periodicMintedTokens.add(_amountToBeMinted);
        
        emit PeriodicMint(_msgSender(), _amountToBeMinted);
    }

    //returns the toal amount of minted tokens
    function getMintedTokensTotal() external view returns (uint256) {
        uint256 totalMinted = publicSaleMintedTokens.add(periodicMintedTokens);
        totalMinted = totalMinted.add(tokensMintedByOwnerFromHalf);
        return totalMinted;
    }

    receive() external payable {}

    //adds a token to the revive basket tokens array
    function addToken(address _tokenAddress, uint256 _tokenWeight)
        external
        onlyOwner
    {
        require(isTokenInReviveBasket[_tokenAddress] == false, "Token is already in revive basket!");
        reviveBasketWeight = reviveBasketWeight.add(_tokenWeight);
        reviveBasketToken memory token = reviveBasketToken(
            _tokenAddress,
            _tokenWeight
        );
        reviveBasketTokens.push(token);
        isTokenInReviveBasket[_tokenAddress] = true;
        emit AddToken(_msgSender(), _tokenAddress, _tokenWeight);
    }

    //removes a token from the revive basket tokens array
    function removeToken(address _tokenAddress) external onlyOwner {
        for (uint256 i = 0; i < reviveBasketTokens.length; i++) {
            if (reviveBasketTokens[i].tokenAddress == _tokenAddress) {
                reviveBasketWeight = reviveBasketWeight.sub(
                    reviveBasketTokens[i].weight
                );
                reviveBasketTokens[i] = reviveBasketTokens[
                    reviveBasketTokens.length.sub(1)
                ];
                reviveBasketTokens.pop();
                isTokenInReviveBasket[_tokenAddress] = false;
                emit RemoveToken(_msgSender(), _tokenAddress);
                break;
            }
        }
    }

    function getTokenWeight(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < reviveBasketTokens.length; i++) {
            if (reviveBasketTokens[i].tokenAddress == _tokenAddress) {
                return reviveBasketTokens[i].weight;
            }
        }
        return 0;
    }

    //returns the amount of bnb that can be used to buy a specific token based
    // on the total bnb amount (_totalBalance) and the token's weight (_tokenWeight)
    function _getBnbAmountToBeUsed(uint256 _totalBalance, uint256 _tokenWeight)
        private
        view
        returns (uint256)
    {
        uint256 amount = (_totalBalance).mul(_tokenWeight).div(reviveBasketWeight);
        return amount;
    }

    //used to swap "_tokenAmount" of tokens of the specified token (_tokenAddress)
    // into bnb and returns the resulted amount
    function _swapExactTokensForBnb(uint256 _tokenAmount, address _tokenAddress)
        private
        returns (uint256)
    {
        uint256 initialBalance = address(this).balance;

        IERC20 tokenContract = IERC20(_tokenAddress);

        tokenContract.approve(
            pancakeSwapRouterAddress,
            ~uint256(0)
        );

        // generate the uniswap pair path of token -> bnb
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = pancakeSwapRouter.WETH();

        pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of bnb
            path,
            address(this),
            block.timestamp + 100 days
        );
        return address(this).balance.sub(initialBalance);
    }

    //swap half of the "_bnbAmount" into the specified token and add liquidity to the BNB -> token
    //pool with the remaining half of the "_bnbAmount"
    function _buyToken(reviveBasketToken memory _token, uint256 _bnbAmount)
        private
    {
        IERC20 tokenContract = IERC20(_token.tokenAddress);

        // generate the uniswap pair path of BNB -> token
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouter.WETH();
        path[1] = _token.tokenAddress;

        //get pair address of the BNB -> token pair
        address pairAddress = factory.getPair(pancakeSwapRouter.WETH(), _token.tokenAddress);

        //if pair don't exist
        if(pairAddress == address(0)) return;

        // capture the contract's current "token" balance.
        // this is so that we can capture exactly the amount of "token" that the
        // swap creates, and not make the liquidity event include any "token" that
        // has been manually sent to the contract
        uint256 tokenAmount = tokenContract.balanceOf(address(this));
        pancakeSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _bnbAmount / 2
        }(0, path, address(this), block.timestamp + 100 days);
        // how much "token" did we just swap into?
        tokenAmount = tokenContract.balanceOf(address(this)).sub(tokenAmount);

        tokenContract.approve(
            pancakeSwapRouterAddress,
            tokenAmount
        );
       //adds liquidity to the BNB -> token
       pancakeSwapRouter.addLiquidityETH{value: _bnbAmount / 2}(
            _token.tokenAddress,
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 100 days
        );
    }

    function handleReviveBasket(uint256 _pulseAmount)
        public
        override
        returns (bool)
    {
        require(_msgSender() == pulseTokenAddress, "Revive basket: this function can only be called by PULSE Token Contract");
        //swap all the received PULSE into BNB
        uint256 bnbAmount = _swapExactTokensForBnb(_pulseAmount, pulseTokenAddress);
        for (uint256 i = 0; i < reviveBasketTokens.length; i++) {
            _buyToken(
                reviveBasketTokens[i],
                _getBnbAmountToBeUsed(bnbAmount, reviveBasketTokens[i].weight)
            );
        }
        return true;
    }

    function _convertTokenLpsIntoBnb(address _tokenAddress, uint256 _lpTokens)
        private
        returns (uint256)
    {

        address pairAddress = factory.getPair(pancakeSwapRouter.WETH(), _tokenAddress);

        if(pairAddress == address(0)) return 0;

        IPancakePair pair = IPancakePair(pairAddress);

        IERC20 token = IERC20(_tokenAddress);

        if(_lpTokens > pair.balanceOf(address(this))) {
            return 0;
        }

        //approve the router to use all the lp's of this contract
        pair.approve(
            pancakeSwapRouterAddress,
            _lpTokens
        );

        //swap all the LP's into BNB and PULSE
        // capture the contract's current BNB and PULSE.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB and pulse that
        // has been manually sent to the contract
        uint256 amountBnb = address(this).balance;
        uint256 amountToken = token.balanceOf(address(this));
        
        pancakeSwapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            _tokenAddress,
            _lpTokens,
            0,
            0,
            address(this),
            block.timestamp + 100 days
        );
        // how much PULSE did we just swap into?
        amountToken = token.balanceOf(address(this)).sub(amountToken);

        //swap the obtained PULSE tokens into BNB
        _swapExactTokensForBnb(amountToken, _tokenAddress);

        // how much BNB did we just swap into?
        amountBnb = address(this).balance.sub(amountBnb);
        return amountBnb;
    }

    //used to swap "_lpTokens" amount of 
    function redeemLpTokens(address _tokenAddress, uint256 _lpTokens) external onlyOwner {
        address pairAddress = factory.getPair(pancakeSwapRouter.WETH(), _tokenAddress);
        if(pairAddress == address(0)) return;
        IPancakePair pair = IPancakePair(pairAddress);
        require(pair.balanceOf(address(this)) >= _lpTokens, "Revive Basket: you don't have enough founds");
        uint256 amountBnb = _convertTokenLpsIntoBnb(_tokenAddress, _lpTokens);

        //generate the uniswap pair path of BNB -> PULSE
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouter.WETH();
        path[1] = pulseTokenAddress;

        uint256 balance = pulseToken.balanceOf(address(this));
        
        pancakeSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountBnb
        }(0, path, address(this), block.timestamp + 100 days);

        balance = pulseToken.balanceOf(address(this)).sub(balance);
        IToken token = IToken(pulseTokenAddress);
        token.deliver(balance);

        emit RedeemLpTokens(_msgSender(), _tokenAddress, _lpTokens);
    }

    function redeemLpTokensPulse(uint256 _lpTokens) external onlyOwner returns(uint256) {
        
        address pairAddress = factory.getPair(pancakeSwapRouter.WETH(), pulseTokenAddress);
        if(pairAddress == address(0)) return 0;

        //get contract interafce of the pancakeSwapPairToken
        IPancakePair  bnbPulsePairContract = IPancakePair(pairAddress);

        //approve the router to use all the LP's of this contract
        bnbPulsePairContract.approve(
            pancakeSwapRouterAddress,
            _lpTokens
        );
        
        //swap all the LP's into BNB and PULSE
        uint256 amountBnb;
        uint256 amountPulse = pulseToken.balanceOf(address(this));
        (,amountBnb) = pancakeSwapRouter
        .removeLiquidityETH(
            pulseTokenAddress,
            _lpTokens,
            0,
            0,
            address(this),
            block.timestamp + 100 days
        );
        //generate the uniswap pair path of BNB -> PULSE
        address[] memory path = new address[](2);
        path[0] = pancakeSwapRouter.WETH();
        path[1] = pulseTokenAddress;

        //converts all of the BNB into PULSE tokens and transfers them to the owner
        pancakeSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountBnb
        }(0, path, address(this), block.timestamp + 100 days);

        // how much BNB did we just swap into?
        amountPulse = pulseToken.balanceOf(address(this)).sub(amountPulse);  
        
        IToken pulse = IToken(pulseTokenAddress);

        pulse.burn(amountPulse);

        emit RedeemLpTokensPulse(_msgSender(), _lpTokens);
    }

    // function burnRemainingEth() external onlyOwner {
    //      //generate the uniswap pair path of BNB -> PULSE
    //     address[] memory path = new address[](2);
    //     path[0] = pancakeSwapRouter.WETH();
    //     path[1] = pulseTokenAddress;

    //     uint256 balance = pulseToken.balanceOf(address(this));
    //     uint256 bnbAmount = address(this).balance;

    //     pancakeSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
    //         value: bnbAmount
    //     }(0, path, address(this), block.timestamp + 100 days);

    //     balance = pulseToken.balanceOf(address(this)).sub(balance);

    //     IToken pulse = IToken(pulseTokenAddress);
    //     pulse.burn(balance);
    //     emit BurnRemainingBNB(_msgSender(), bnbAmount);
    // }

    function burnRemainingPulse() external onlyOwner { 
        IToken pulse = IToken(pulseTokenAddress);
        uint256 pulseAmount = pulseToken.balanceOf(address(this));
        pulse.burn(pulseAmount);
        emit BurnRemainingPulse(_msgSender(), pulseAmount);
    }

    function swapAndLiquify(uint256 pulseAmount) external override{
        require(_msgSender() == pulseTokenAddress, "Revive basket: this function can only be called by PULSE Token Contract");
        // split the contract balance into halves
        uint256 half = pulseAmount.div(2);
        uint256 otherHalf = pulseAmount.sub(half);
        
        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBnbBalance = address(this).balance;
        uint256 initialPulseBalance  = pulseToken.balanceOf(address(this));

        // swap tokens for BNB
        _swapTokensForBnb(half); // <- this breaks the BNB -> PULSE swap when swap+liquify is triggered
        // how much BNB did we just swap into?
        uint256 bnbAmount = address(this).balance.sub(initialBnbBalance);
        uint256 actualPulseSwapped = initialPulseBalance.sub(pulseToken.balanceOf(address(this)));
        otherHalf = otherHalf.add(half.sub(actualPulseSwapped));
        _addLiquidity(otherHalf, bnbAmount);        
    }

    function _swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> Bnb
        address[] memory path = new address[](2);
        path[0] = pulseTokenAddress;
        path[1] = pancakeSwapRouter.WETH();

        //approve "tokenAmount" of tokens for the Uniswap Router to use
        pulseToken.approve(address(pancakeSwapRouter), tokenAmount);
        
        // make the swap
        pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp + 100 days
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        pulseToken.approve(address(pancakeSwapRouter), tokenAmount);

        pancakeSwapRouter.addLiquidityETH{
            value: bnbAmount
        }(
            pulseTokenAddress,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 100 days
        );
        
        // if(balanceOf(address(this)) > 0) {
        //     _transfer(address(this), minterAddress, balanceOf(address(this)));
        // }

        // if(address(this).balance > 0) { 
        //     payable(minterAddress).transfer(address(this).balance);
        // }
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IPulseManager {

    function handleReviveBasket(uint256 pulseAmount) external returns(bool);
    function swapAndLiquify(uint256 pulseAmount) external;

}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IToken {

    //used to deliver a specific amount of tokens to the all balance holders
    function deliver(uint256 tAmount) external;

    //returns the number of decimals that the token has
    function decimals() external view returns(uint8);

    function burn(uint256 tokenAmount) external;
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: substraction overflow");
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

    function mod(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division with 0");
        return a % b;
    }

    function div(
        uint256 a,
        uint256 b
    ) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by 0");
        return a / b;
    }
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {

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

    function mint(address to, uint256 amount) external;
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



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

