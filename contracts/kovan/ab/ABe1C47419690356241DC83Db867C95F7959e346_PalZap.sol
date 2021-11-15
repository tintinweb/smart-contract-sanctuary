//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     
pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT


import "./interfaces/IERC20.sol";
import "./interfaces/IPaladinController.sol";
import "./interfaces/IPalPool.sol";
import "./interfaces/IPalLoanToken.sol";
import "./interfaces/IStakedAave.sol";

import "./utils/Ownable.sol";
import "./utils/Pausable.sol";
import "./utils/SafeERC20.sol";

/** @title PaladinZap contract  */
/// @author Paladin
contract PalZap is Ownable, Pausable {
    using SafeERC20 for IERC20;

    //Storage
    mapping(address => bool) private allowedSwapTargets;

    IPaladinController public controller;
    IPalLoanToken public loanToken;

    address private aaveAddress;
    address private stkAaveAddress;

    //Events
    event ZapDeposit(address sender, address palPool, uint256 palTokenAmount);
    event ZapBorrow(address sender, address palPool, uint256 palLoanTokenId);
    event ZapExpandBorrow(address sender, address palPool, address palLoan, uint256 palLoanTokenId);


    //Constructor
    constructor(
        address _controller,
        address _loanToken,
        address _swapTarget,
        address _aaveAddress,
        address _stkAaveAddress
    ) {
        controller = IPaladinController(_controller);
        loanToken = IPalLoanToken(_loanToken);

        allowedSwapTargets[_swapTarget] = true;

        aaveAddress = _aaveAddress;
        stkAaveAddress = _stkAaveAddress;
    }


    //Functions
    function zapDeposit(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _poolAddress,
        uint256 _amount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) external payable whenNotPaused returns(uint){
        //Check valid PalPool Address
        require(controller.isPalPool(_poolAddress), "Paladin Zap : Incorrect PalPool");
        IPalPool _pool = IPalPool(_poolAddress);

        //Check input values
        require(
            _toTokenAddress!= address(0) && _poolAddress!= address(0) && _swapTarget!= address(0),
            "Paladin Zap : Zero Address"
        );
        require(_amount > 0 || msg.value > 0 , "Paladin Zap : Zero amount");
        require(_toTokenAddress == _pool.underlying(), "Paladin Zap : Incorrect toToken");

        //Pull the fromToken to the Zap
        uint _pulledAmount = _pullTokens(_fromTokenAddress, _amount);

        //Check the swapTarget is allowed in the Zap
        require(allowedSwapTargets[_swapTarget], "Paladin Zap : SwapTarget not allowed");

        //Make the swap and receive the fromToken
        uint _receivedAmount = _makeSwap(_fromTokenAddress, _toTokenAddress, _pulledAmount, _swapTarget, _allowanceTarget, _swapData);

        //Deposit the fromToken to the PalPool and receive palTokens
        uint _palTokenAmount = _depositInPool(_toTokenAddress, _poolAddress, _receivedAmount);

        //Send the palTokens to the user
        address _palTokenAddress = _pool.palToken();
        IERC20(_palTokenAddress).safeTransfer(msg.sender, _palTokenAmount);

        //emit Event
        emit ZapDeposit(msg.sender, _poolAddress, _palTokenAmount);

        return _palTokenAmount;
    }

    function zapBorrow(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _poolAddress,
        address _delegatee,
        uint256 _borrowAmount,
        uint256 _feesAmount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) external payable whenNotPaused returns(uint){
        //Check valid PalPool Address
        require(controller.isPalPool(_poolAddress), "Paladin Zap : Incorrect PalPool");
        IPalPool _pool = IPalPool(_poolAddress);

        //Check input values
        require(
            _toTokenAddress!= address(0) && _poolAddress!= address(0) && _delegatee!= address(0) && _swapTarget!= address(0),
            "Paladin Zap : Zero Address"
        );
        require(_borrowAmount > 0 && (_feesAmount > 0 || msg.value > 0), "Paladin Zap : Zero amount");
        require(_toTokenAddress == _pool.underlying(), "Paladin Zap : Incorrect toToken");

        //Pull the fromToken to the Zap
        uint _pulledAmount = _pullTokens(_fromTokenAddress, _feesAmount);

        //Check the swapTarget is allowed in the Zap
        require(allowedSwapTargets[_swapTarget], "Paladin Zap : SwapTarget not allowed");

        //Make the swap and receive the fromToken
        uint _receivedAmount = _makeSwap(_fromTokenAddress, _toTokenAddress, _pulledAmount, _swapTarget, _allowanceTarget, _swapData);

        uint _minBorrowAmount = _pool.minBorrowFees(_borrowAmount);
        require(_receivedAmount >= _minBorrowAmount, "Paladin Zap : Fee amount too low");

        //Make the Borrow to the PalPool, and get the new PalLoanToken Id
        uint _newTokenId = _borrowFromPool(_toTokenAddress, _poolAddress, _delegatee, _borrowAmount, _receivedAmount);

        //Check the Zap received the PalLoanToken
        require(
            loanToken.ownerOf(_newTokenId) == address(this),
            "Paladin Zap : PalPool Borrow failed"
        );

        //Send the PalLoanToken to the user
        loanToken.safeTransferFrom(address(this), msg.sender, _newTokenId);

        //emit Event
        emit ZapBorrow(msg.sender, _poolAddress, _newTokenId);

        return _newTokenId;
    }


    function zapExpandBorrow(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _loanAddress,
        address _poolAddress,
        uint256 _amount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) external payable whenNotPaused returns(bool){
        //Check valid PalPool Address
        require(controller.isPalPool(_poolAddress), "Paladin Zap : Incorrect PalPool");
        IPalPool _pool = IPalPool(_poolAddress);

        //Check input values
        require(
            _toTokenAddress!= address(0) && _poolAddress!= address(0) && _loanAddress!= address(0) && _swapTarget!= address(0),
            "Paladin Zap : Zero Address"
        );
        require(_amount > 0 || msg.value > 0 , "Paladin Zap : Zero amount");
        require(_toTokenAddress == _pool.underlying(), "Paladin Zap : Incorrect toToken");

        //Check PalLoan ownership
        require(_pool.isLoanOwner(_loanAddress, msg.sender), "Paladin Zap : Not PalLoan owner");

        uint _tokenId = _pool.idOfLoan(_loanAddress);

        //Check PalLoan is linked to the given PalPool
        require(loanToken.poolOf(_tokenId) == _poolAddress, "Paladin Zap : Incorrect PalPool");

        //Check allowance to transfer the PalLoanToken
        require(loanToken.isApprovedForAll(msg.sender, address(this)), "Paladin Zap : Not approved for PalLoanToken");

        //Transfer PalLoanToken to Zap
        loanToken.safeTransferFrom(msg.sender, address(this), _tokenId);

        //Pull the fromToken to the Zap
        uint _pulledAmount = _pullTokens(_fromTokenAddress, _amount);

        //Check the swapTarget is allowed in the Zap
        require(allowedSwapTargets[_swapTarget], "Paladin Zap : SwapTarget not allowed");

        //Make the swap and receive the fromToken
        uint _receivedAmount = _makeSwap(_fromTokenAddress, _toTokenAddress, _pulledAmount, _swapTarget, _allowanceTarget, _swapData);

        //Pay fees of the PalLoan
        _increaseFees(_toTokenAddress, _loanAddress, _poolAddress, _receivedAmount);

        //Return the PalLoanToken to the user
        loanToken.safeTransferFrom(address(this), msg.sender, _tokenId);

        //emit Event
        emit ZapExpandBorrow(msg.sender, _poolAddress, _loanAddress, _tokenId);

        return true;
    }





    //Internal Functions
    function _pullTokens(
        address _fromTokenAddress,
        uint256 _amount
    ) internal returns(uint256 _receivedAmount) {
        if(_fromTokenAddress == address(0)){
            require(msg.value > 0 , "Paladin Zap : No ETH received");

            return msg.value;
        }
        
        require(_amount > 0 , "Paladin Zap : Token amount null");
        require(msg.value == 0, "Paladin Zap : Multiple tokens sent");

        IERC20 _fromToken = IERC20(_fromTokenAddress);

        require(_fromToken.allowance(msg.sender, address(this)) >= _amount, "Paladin Zap : Allowance too low");

        _fromToken.safeTransferFrom(msg.sender, address(this), _amount);

        return _amount;
    }


    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return 'Transaction reverted silently';
    
        assembly {
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string));
    }

    function _makeSwap(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        address _allowanceTarget,
        bytes memory _swapData
    ) internal returns(uint256 _returnAmount) {
        //same token
        if(_fromTokenAddress == _toTokenAddress){
            return _amount;
        }

        //AAVE -> stkAAVE : just need to stake in the Safety Module
        if(_fromTokenAddress == aaveAddress && _toTokenAddress == stkAaveAddress){
            return _stakeInAave(_amount);
        }

        //If output token is stkAAVE -> swap to AAVE then stake in the Safety Module 
        address _outputTokenAddress = _toTokenAddress;
        if(_toTokenAddress == stkAaveAddress){
            _outputTokenAddress = aaveAddress;
        }

        uint256 _valueSwap;
        if (_fromTokenAddress == address(0)) {
            _valueSwap = _amount;
        } else {
            IERC20(_fromTokenAddress).safeIncreaseAllowance(_allowanceTarget, _amount);
        }

        IERC20 _outputToken = IERC20(_outputTokenAddress);
        uint256 _intitialBalance = _outputToken.balanceOf(address(this));

        //Make the swap
        (bool _success, bytes memory _res) = _swapTarget.call{ value: _valueSwap }(_swapData);
        require(_success, _getRevertMsg(_res));

        _returnAmount = _outputToken.balanceOf(address(this)) - _intitialBalance;

        //If the swap return AAVE, stake them to get stkAAVE
        if(_toTokenAddress == stkAaveAddress){
            _returnAmount = _stakeInAave(_amount);
        }

        require(_returnAmount > 0, "Paladin Zap : Swap output null");
    }


    function _stakeInAave(
        uint256 _amount
    ) internal returns(uint256 _stakedAmount) {
        IStakedAave _stkAave = IStakedAave(stkAaveAddress);

        uint256 _initialBalance = _stkAave.balanceOf(address(this));

        IERC20(aaveAddress).safeApprove(stkAaveAddress, _amount);
        _stkAave.stake(address(this), _amount);

        uint256 _newBalance = _stkAave.balanceOf(address(this));
        _stakedAmount = _newBalance - _initialBalance;

        require(_stakedAmount == _amount, "Paladin Zap : Error staking in Aave");

    }


    function _depositInPool(
        address _tokenAddress,
        address _poolAddress,
        uint256 _amount
    ) internal returns(uint256 _palTokenAmount) {
        IPalPool _pool = IPalPool(_poolAddress);
        IERC20 _palToken = IERC20(_pool.palToken());

        uint256 _initialBalance = _palToken.balanceOf(address(this));

        IERC20(_tokenAddress).safeApprove(_poolAddress, _amount);

        _palTokenAmount = _pool.deposit(_amount);

        uint256 _newBalance = _palToken.balanceOf(address(this));

        require(_newBalance - _initialBalance == _palTokenAmount, "Paladin Zap : Error depositing in PalPool");
        
    }


    function _borrowFromPool(
        address _tokenAddress,
        address _poolAddress,
        address _delegatee,
        uint256 _borrowAmount,
        uint256 _feesAmount
    ) internal returns(uint256 _tokenId) {
        IERC20(_tokenAddress).safeApprove(_poolAddress, _feesAmount);

        _tokenId = IPalPool(_poolAddress).borrow(_delegatee, _borrowAmount, _feesAmount);
    }


    function _increaseFees(
        address _tokenAddress,
        address _loanAddress,
        address _poolAddress,
        uint256 _feesAmount
    ) internal returns(bool) {
        IERC20(_tokenAddress).safeApprove(_poolAddress, _feesAmount);

        uint _paidFees = IPalPool(_poolAddress).expandBorrow(_loanAddress, _feesAmount);

        require(_feesAmount == _paidFees ,"Paladin Zap : Error expanding Borrow");

        return true;
    }


    //Admin Functions

    // In case tokens are stuck in the contract
    function sendToken(address _tokenAddress, address payable _recipient) external onlyOwner {
        if(_tokenAddress == address(0)){
            Address.sendValue(_recipient, address(this).balance);
        }
        else{
            IERC20(_tokenAddress).safeTransfer(_recipient, IERC20(_tokenAddress).balanceOf(address(this)));
        }
    }

    /**
    * @notice Set a new Controller
    * @dev Loads the new Controller for the Pool
    * @param  _newController address of the new Controller
    */
    function setNewController(address _newController) external onlyOwner {
        controller = IPaladinController(_newController);
    }

    function setNewPalLoanToken(address _newPalLoanToken) external onlyOwner {
        loanToken = IPalLoanToken(_newPalLoanToken);
    }


    function addSwapTarget(address _swapTarget) external onlyOwner {
        allowedSwapTargets[_swapTarget] = true;
    }



    receive() external payable {
        require(msg.sender != tx.origin, "Paladin Zap : Do not send ETH directly");
    }

}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

/** @title Paladin Controller Interface  */
/// @author Paladin
interface IPaladinController {
    
    function isPalPool(address pool) external view returns(bool);

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.8.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

/** @title palPool Interface  */
/// @author Paladin
interface IPalPool {

    //Events
    /** @notice Event when an user deposit tokens in the pool */
    event Deposit(address user, uint amount, address palPool);
    /** @notice Event when an user withdraw tokens from the pool */
    event Withdraw(address user, uint amount, address palPool);
    /** @notice Event when a loan is started */
    event NewLoan(
        address borrower,
        address delegatee,
        address underlying,
        uint amount,
        address palPool,
        address loanAddress,
        uint256 palLoanTokenId,
        uint startBlock);
    /** @notice Event when the fee amount in the loan is updated */
    event ExpandLoan(
        address borrower,
        address delegatee,
        address underlying,
        address palPool,
        uint newFeesAmount,
        address loanAddress,
        uint256 palLoanTokenId
    );
    /** @notice Event when the delegatee of the loan is updated */
    event ChangeLoanDelegatee(
        address borrower,
        address newDelegatee,
        address underlying,
        address palPool,
        address loanAddress,
        uint256 palLoanTokenId
    );
    /** @notice Event when a loan is ended */
    event CloseLoan(
        address borrower,
        address delegatee,
        address underlying,
        uint amount,
        address palPool,
        uint usedFees,
        address loanAddress,
        uint256 palLoanTokenId,
        bool wasKilled
    );

    /** @notice Reserve Events */
    event AddReserve(uint amount);
    event RemoveReserve(uint amount);


    function underlying() external view returns(address);
    function palToken() external view returns(address);

    //Functions
    function deposit(uint _amount) external returns(uint);
    function withdraw(uint _amount) external returns(uint);
    
    function borrow(address _delegatee, uint _amount, uint _feeAmount) external returns(uint);
    function expandBorrow(address _loanPool, uint _feeAmount) external returns(uint);
    function closeBorrow(address _loanPool) external;
    function killBorrow(address _loanPool) external;
    function changeBorrowDelegatee(address _loanPool, address _newDelegatee) external;

    function balanceOf(address _account) external view returns(uint);
    function underlyingBalanceOf(address _account) external view returns(uint);

    function isLoanOwner(address _loanAddress, address _user) external view returns(bool);
    function idOfLoan(address _loanAddress) external view returns(uint256);

    function getLoansPools() external view returns(address [] memory);
    function getLoansByBorrower(address _borrower) external view returns(address [] memory);
    function getBorrowData(address _loanAddress) external view returns(
        address _borrower,
        address _delegatee,
        address _loanPool,
        uint256 _palLoanTokenId,
        uint _amount,
        address _underlying,
        uint _feesAmount,
        uint _feesUsed,
        uint _startBlock,
        uint _closeBlock,
        bool _closed,
        bool _killed
    );

    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);

    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);

    function minBorrowFees(uint _amount) external view returns (uint);

    function isKillable(address _loan) external view returns(bool);

    //Admin functions : 
    function setNewController(address _newController) external;
    function setNewInterestModule(address _interestModule) external;
    function setNewDelegator(address _delegator) external;

    function updateMinBorrowLength(uint _length) external;
    function updatePoolFactors(uint _reserveFactor, uint _killerRatio) external;

    function addReserve(uint _amount) external;
    function removeReserve(uint _amount, address _recipient) external;

}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.8.0;
pragma abicoder v2;
//SPDX-License-Identifier: MIT

import "./IERC721.sol";

/** @title palLoanToken Interface  */
/// @author Paladin
interface IPalLoanToken is IERC721 {

    //Events

    /** @notice Event when a new Loan Token is minted */
    event NewLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);
    /** @notice Event when a Loan Token is burned */
    event BurnLoanToken(address palPool, address indexed owner, address indexed palLoan, uint256 indexed tokenId);


    //Functions
    function mint(address to, address palPool, address palLoan) external returns(uint256);
    function burn(uint256 tokenId) external returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenOfByIndex(address owner, uint256 tokenIdex) external view returns (uint256);
    function loanOf(uint256 tokenId) external view returns(address);
    function poolOf(uint256 tokenId) external view returns(address);
    function loansOf(address owner) external view returns(address[] memory);
    function tokensOf(address owner) external view returns(uint256[] memory);
    function loansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allTokensOf(address owner) external view returns(uint256[] memory);
    function allLoansOf(address owner) external view returns(address[] memory);
    function allLoansOfForPool(address owner, address palPool) external view returns(address[] memory);
    function allOwnerOf(uint256 tokenId) external view returns(address);

    function isBurned(uint256 tokenId) external view returns(bool);

    //Admin functions
    function setNewController(address _newController) external;
    function setNewBaseURI(string memory _newBaseURI) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStakedAave {
    function stake(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

