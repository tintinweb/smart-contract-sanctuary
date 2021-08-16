// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./IUniswapV2Pair.sol";
import "./IWrappedERC20.sol";

import "./IWETH.sol";
import "./IFloorCalculator.sol";
import "./IWrappedERC20Events.sol";
import "./SafeERC20.sol";
import "./IWizardEventGate.sol";
import "./IMagicTransferGate.sol";

import ".//ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./TokensRecoverableUpg.sol";



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


contract axBNBLiquidity is ERC20Upgradeable, IWrappedERC20Events, OwnableUpgradeable, TokensRecoverableUpg
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20 for IERC20;
    using SafeMathUpgradeable for uint256;

    mapping(address=>bool) wrappedTokens;
    mapping(address=>uint256) supplyFrom;


    address stakeAddress;
    address treasuryAddress;
    uint256 stakeFee;//0.0 %
    uint256 treasuryFee;//0.0 %
    mapping(address=>bool) IGNORED_ADDRESSES;
    address public wizardZapper;
    
    IWizardEventGate public wizardEventGate;
    address public LPAddress; // Wizard <-> Magic SLP

    IFloorCalculator public floorCalculator;
    mapping (address => bool) public sweepers;
    
    event TransferParamsSet(address stakeAddress, address treasuryAddress, uint256 stakeFee, uint256 treasuryFee);
    event LPAddressSet(address LPAddress);
    event ZapperSet(address wizardZapper);

    function initialize(IWrappedERC20 _wrappedToken) public initializer  {

        __Ownable_init_unchained();
        __ERC20_init("Vein","VEIN");

        if (_wrappedToken.decimals() != 18) {
            _setupDecimals(_wrappedToken.decimals());
        }
        wrappedTokens[address(_wrappedToken)]=true;
        stakeFee = 1000; //1%
        treasuryFee = 1000; //1%
    }

    function addLPpair(IERC20 _wrappedToken) external onlyOwner{
        if (_wrappedToken.decimals() != 18 || _wrappedToken.decimals()>decimals()) {
            _setupDecimals(_wrappedToken.decimals());
        }
        wrappedTokens[address(_wrappedToken)]=true;
    }

    function removeLPpair(address _wrappedToken) external onlyOwner{
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

    function setFloorCalculator(IFloorCalculator _floorCalculator) public  onlyOwner()
    {
        floorCalculator = _floorCalculator;
    }

    function setSweeper(address sweeper, bool allow) public  onlyOwner()
    {
        sweepers[sweeper] = allow;
    }

    //wrappedTokens are all the axBNB<->dMagic pair addresses 
    function sweepFloor(IERC20[] memory _wrappedTokens, address to) public  returns (uint256 amountSwept)
    {
        require (to != address(0));
        require (sweepers[msg.sender], "Sweepers only");

        amountSwept = floorCalculator.calculateSubFloorWizard(_wrappedTokens, IERC20(address(this)));// its always constant for Wizard or any LP pairs
        if (amountSwept > 0) {
            _wrappedTokens[0].safeTransfer(to, amountSwept);
        }
    }

    function _beforeWithdrawTokens(uint256) internal pure
    { 
        revert("liquidity is locked");
    }

    function setEventGate(IWizardEventGate _wizardEventGate) external onlyOwner()
    {
        wizardEventGate = _wizardEventGate;
    }

    function setLPAddress(address _LPAddress) external onlyOwner()
    {
        require(_LPAddress != address(0), "axBNBLiquidity: _LPAddress cannot be zero address");
        LPAddress = _LPAddress;
        emit LPAddressSet(LPAddress);
    }

    function setZapper(address _wizardZapper) external onlyOwner() {
        require(_wizardZapper != address(0), "axBNBLiquidity: _wizardZapper cannot be zero address");
        wizardZapper = _wizardZapper;   
        emit ZapperSet(wizardZapper);     
    }

    function setIgnoredAddresses(address _ignoredAddress, bool ignore)external onlyOwner{
        IGNORED_ADDRESSES[_ignoredAddress]=ignore;
    }

    function setIgnoredAddressBulk(address[] memory _ignoredAddressBulk, bool ignore)external onlyOwner{
        
        for(uint i=0;i<_ignoredAddressBulk.length;i++){
            address _ignoredAddress = _ignoredAddressBulk[i];
            IGNORED_ADDRESSES[_ignoredAddress] = ignore;
        }
    }

    function isIgnored(address _ignoredAddress) public view returns (bool) {
        return IGNORED_ADDRESSES[_ignoredAddress];
    }
   
    function setTransferParameters(address _stakeAddress, address _treasuryAddress, uint256 _stakeFee, uint256 _treasuryFee) onlyOwner external{
        require(_stakeAddress != address(0), "axBNBLiquidity: _stakeAddress cannot be zero address");
        require(_treasuryAddress != address(0), "axBNBLiquidity: _treasuryAddress cannot be zero address");
        stakeAddress=_stakeAddress;
        treasuryAddress=_treasuryAddress;
        stakeFee=_stakeFee;
        treasuryFee=_treasuryFee;
        emit TransferParamsSet(_stakeAddress, _treasuryAddress, _stakeFee, _treasuryFee);

    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "Wizard: transfer from the zero address");
        require(recipient != address(0), "Wizard: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "Wizard: transfer amount exceeds balance");

        if(sender == wizardZapper && recipient != address(wizardEventGate) && recipient != LPAddress ) 
        {    
           _balances[address(wizardEventGate)] = _balances[address(wizardEventGate)].add(amount);
            emit Transfer(sender, address(wizardEventGate), amount);
            wizardEventGate.lockWizard(sender, recipient, amount); 
        }
        else if(sender == LPAddress && recipient != address(wizardEventGate) && recipient != wizardZapper)
        {   
            uint256 stakingFeeAmt = amount.mul(stakeFee).div(100000); 
            uint256 treasuryFeeAmt = amount.mul(treasuryFee).div(100000); 
            uint256 remAmount = amount.sub(stakingFeeAmt).sub(treasuryFeeAmt);

            _balances[stakeAddress] = _balances[stakeAddress].add(stakingFeeAmt);
            _balances[treasuryAddress] = _balances[treasuryAddress].add(treasuryFeeAmt);
            
            emit Transfer(sender, stakeAddress, stakingFeeAmt);
            emit Transfer(sender, treasuryAddress, treasuryFeeAmt);

            _balances[address(wizardEventGate)] = _balances[address(wizardEventGate)].add(remAmount);
            emit Transfer(sender, address(wizardEventGate), remAmount);
            wizardEventGate.lockWizard(sender, recipient, remAmount); 
        }

        else if(IGNORED_ADDRESSES[recipient]){
            _balances[recipient]=_balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
        else{
            uint256 stakingFeeAmt = amount.mul(stakeFee).div(100000); 
            uint256 treasuryFeeAmt = amount.mul(treasuryFee).div(100000); 
            uint256 remAmount = amount.sub(stakingFeeAmt).sub(treasuryFeeAmt);

            _balances[stakeAddress] = _balances[stakeAddress].add(stakingFeeAmt);
            _balances[treasuryAddress] = _balances[treasuryAddress].add(treasuryFeeAmt);
            _balances[recipient] = _balances[recipient].add(remAmount);
            
            emit Transfer(sender, stakeAddress, stakingFeeAmt);
            emit Transfer(sender, treasuryAddress, treasuryFeeAmt);
            emit Transfer(sender, recipient, remAmount);
        }
    }


    function _beforeDepositTokens(uint256 _amount) internal virtual view { }
}