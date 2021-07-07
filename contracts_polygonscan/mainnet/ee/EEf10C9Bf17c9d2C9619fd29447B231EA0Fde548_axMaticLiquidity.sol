// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./IWrappedERC20.sol";
import "./TokensRecoverable.sol";
import "./SafeERC20.sol";

import "./IWETH.sol";
import "./SafeMath.sol";
import "./IFloorCalculator.sol";
import "./IWrappedERC20Events.sol";
import "./ReentrancyGuard.sol";


contract WrappedERC20s is ERC20, TokensRecoverable, IWrappedERC20Events
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // IERC20 public immutable override wrappedToken;
    mapping(address=>bool) wrappedTokens;
    mapping(address=>uint256) supplyFrom;
    

    constructor (IERC20 _wrappedToken, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {        
        if (_wrappedToken.decimals() != 18) {
            _setupDecimals(_wrappedToken.decimals());
        }
        wrappedTokens[address(_wrappedToken)]=true;
    }

    function addLPpair(IERC20 _wrappedToken) external ownerOnly{
        if (_wrappedToken.decimals() != 18 || _wrappedToken.decimals()>decimals) {
            _setupDecimals(_wrappedToken.decimals());
        }
        wrappedTokens[address(_wrappedToken)]=true;
    }

    function removeLPpair(address _wrappedToken) external ownerOnly{
        wrappedTokens[_wrappedToken]=false;
    }

    function depositTokens(address _wrappedToken, uint256 _amount) public 
    {
        _beforeDepositTokens(_amount);
        require(wrappedTokens[_wrappedToken],"This token cannot be used to deposit");

        IERC20 wrappedToken=IERC20(_wrappedToken);
        uint256 myBalance = wrappedToken.balanceOf(address(this));

        wrappedToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 received = wrappedToken.balanceOf(address(this)).sub(myBalance);
        
        supplyFrom[_wrappedToken]=supplyFrom[_wrappedToken].add(_amount);

        _mint(msg.sender, received);
        emit Deposit(msg.sender, _amount);
    }

    // function withdrawTokens(uint256 _amount) public override
    // {
    //     _beforeWithdrawTokens(_amount);
    //     _burn(msg.sender, _amount);
    //     uint256 myBalance = wrappedToken.balanceOf(address(this));
    //     wrappedToken.safeTransfer(msg.sender, _amount);
    //     require (wrappedToken.balanceOf(address(this)) == myBalance.sub(_amount), "Transfer not exact");

    //     emit Withdrawal(msg.sender, _amount);
    // }

    function canRecoverTokens(IERC20 token) internal virtual override view returns (bool) 
    {
        return token != this && !wrappedTokens[address(token)];
    }

    function _beforeDepositTokens(uint256 _amount) internal virtual view { }
    function _beforeWithdrawTokens(uint256 _amount) internal virtual view { }
}


pragma solidity 0.7.4;

interface IERC31337 is IWrappedERC20Events
{

    function addLPpair(address _wrappedToken) external ;

    function removeLPpair(address _wrappedToken) external ;
    function depositTokens(address _wrappedToken, uint256 _amount) external; 

    function floorCalculator() external view returns (IFloorCalculator);
    function sweepers(address _sweeper) external view returns (bool);
    
    function setFloorCalculator(IFloorCalculator _floorCalculator) external;
    function setSweeper(address _sweeper, bool _allow) external;
    function sweepFloor(IERC20[] memory wrappedTokens, address to)  external returns (uint256 amountSwept);
}


contract ERC31337 is WrappedERC20s
{
    using SafeERC20 for IERC20;

    IFloorCalculator public floorCalculator;
    
    mapping (address => bool) public sweepers;

    constructor(IERC20 _wrappedToken, string memory _name, string memory _symbol)
        WrappedERC20s(_wrappedToken, _name, _symbol)
    {
    }

    function setFloorCalculator(IFloorCalculator _floorCalculator) public  ownerOnly()
    {
        floorCalculator = _floorCalculator;
    }

    function setSweeper(address sweeper, bool allow) public ownerOnly()
    {
        sweepers[sweeper] = allow;
    }

    //wrappedTokens are all the axMatic<->dMagic pair addresses 
    function sweepFloor(IERC20[] memory wrappedTokens, address to) public  returns (uint256 amountSwept)
    {
        require (to != address(0));
        require (sweepers[msg.sender], "Sweepers only");

        amountSwept = floorCalculator.calculateSubFloorNight(wrappedTokens, this);// its always constant for DRAX or any LP pairs
        if (amountSwept > 0) {
            wrappedTokens[0].safeTransfer(to, amountSwept);
        }
    }
}



contract axMaticLiquidity is ERC31337
{
    using SafeMath for uint256;

    address stakeAddress;
    address treasuryAddress;
    uint256 stakeFee=700;//0.0 %
    uint256 treasuryFee=300;//0.0 %
    mapping(address=>bool) IGNORED_ADDRESSES;


    
    constructor(IUniswapV2Pair _pair, string memory _name, string memory _symbol)
        ERC31337(
            IERC20(address(_pair)), 
            _name,
            _symbol)
    {
    }

    function _beforeWithdrawTokens(uint256) internal override pure
    { 
        revert("axMatic liquidity is locked");
    }

    function setIgnoredAddresses(address _ignoredAddress, bool ignore)external ownerOnly{
        IGNORED_ADDRESSES[_ignoredAddress]=ignore;
    }

    function setIgnoredAddressBulk(address[] memory _ignoredAddressBulk, bool ignore)external ownerOnly{
        
        for(uint i=0;i<_ignoredAddressBulk.length;i++){
            address _ignoredAddress = _ignoredAddressBulk[i];
            IGNORED_ADDRESSES[_ignoredAddress] = ignore;
        }
    }

    function isIgnored(address _ignoredAddress) public view returns (bool) {
        return IGNORED_ADDRESSES[_ignoredAddress];
    }
   
    function setTransferParameters(address _stakeAddress, address _treasuryAddress, uint256 _stakeFee, uint256 _treasuryFee) ownerOnly external{
        stakeAddress=_stakeAddress;
        treasuryAddress=_treasuryAddress;
        stakeFee=_stakeFee;
        treasuryFee=_treasuryFee;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");

        if(IGNORED_ADDRESSES[recipient]){
            _balanceOf[recipient]=_balanceOf[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        else{
            uint256 stakingFeeAmt = amount.mul(stakeFee).div(100000); 
            uint256 treasuryFeeAmt = amount.mul(treasuryFee).div(100000); 
            uint256 remAmount = amount.sub(stakingFeeAmt).sub(treasuryFeeAmt);

            _balanceOf[stakeAddress] = _balanceOf[stakeAddress].add(stakingFeeAmt);
            _balanceOf[treasuryAddress] = _balanceOf[treasuryAddress].add(treasuryFeeAmt);
            _balanceOf[recipient] = _balanceOf[recipient].add(remAmount);
            
            emit Transfer(sender, stakeAddress, stakingFeeAmt);
            emit Transfer(sender, treasuryAddress, treasuryFeeAmt);
            emit Transfer(sender, recipient, remAmount);
        }
    }

}