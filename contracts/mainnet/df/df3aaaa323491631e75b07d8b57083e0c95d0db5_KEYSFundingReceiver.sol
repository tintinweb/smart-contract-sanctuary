//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./IKeysStaking.sol";

/**
 *
 * KEYS Funding Receiver
 * Will Allocate Funding To Different Sources
 * Contract Developed By DeFi Mark (MoonMark)
 *
 */
contract KEYSFundingReceiver {
    
    using Address for address;
    
    // Farming Manager
    address public farm;
    address public stake;
    address public multisig;

    // KEYS
    address public constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;
    
    // allocation to farm + stake + multisig
    uint256 public farmFee;
    uint256 public stakeFee;
    uint256 public multisigFee;
    
    // ownership
    address public _master;
    modifier onlyMaster(){require(_master == msg.sender, 'Sender Not Master'); _;}
    
    constructor() {
    
        _master = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
        multisig = 0xfCacEAa7b4cf845f2cfcE6a3dA680dF1BB05015c;
        farm = 0x810487135d29f35f06f1075b48D5978F1791d743;
        stake = 0xF09504B63a199158312807c5f05DaEcA734855D9;
    
        stakeFee = 10;
        farmFee = 80;
        multisigFee = 10;

    }
    
    event SetFarm(address farm);
    event SetStaker(address staker);
    event SetMultisig(address multisig);
    event SetFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent);
    event Withdrawal(uint256 amount);
    event OwnershipTransferred(address newOwner);
    
    // MASTER 
    
    function setFarm(address _farm) external onlyMaster {
        farm = _farm;
        emit SetFarm(_farm);
    }
    
    function setStake(address _stake) external onlyMaster {
        stake = _stake;
        emit SetStaker(_stake);
    }
    
    function setMultisig(address _multisig) external onlyMaster {
        multisig = _multisig;
        emit SetMultisig(_multisig);
    }
    
    function setFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent) external onlyMaster {
        farmFee = farmPercentage;
        stakeFee = stakePercent;
        multisigFee = multisigPercent;
        emit SetFundPercents(farmPercentage, stakePercent, multisigPercent);
    }
    
    function manualWithdraw(address token) external onlyMaster {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0);
        IERC20(token).transfer(_master, bal);
        emit Withdrawal(bal);
    }
    
    function ETHWithdrawal() external onlyMaster returns (bool s){
        uint256 bal = address(this).balance;
        require(bal > 0);
        (s,) = payable(_master).call{value: bal}("");
        emit Withdrawal(bal);
    }
    
    function transferMaster(address newMaster) external onlyMaster {
        _master = newMaster;
        emit OwnershipTransferred(newMaster);
    }
    
    
    // ONLY APPROVED
    
    function distribute() external {
        _distributeYield();
    }

    // PRIVATE
    
    function _distributeYield() private {
        
        uint256 keysBal = IERC20(KEYS).balanceOf(address(this));
        
        uint256 farmBal = (keysBal * farmFee) / 10**2;
        uint256 sigBal = (keysBal * multisigFee) / 10**2;
        uint256 stakeBal = keysBal - (farmBal + sigBal);

        if (farmBal > 0 && farm != address(0)) {
            IERC20(KEYS).approve(farm, farmBal);
            IKeysStaking(farm).deposit(farmBal);
        }
        
        if (stakeBal > 0 && stake != address(0)) {
            IERC20(KEYS).approve(stake, stakeBal);
            IKeysStaking(stake).deposit(stakeBal);
        }
        
        if (sigBal > 0 && multisig != address(0)) {
            IERC20(KEYS).transfer(multisig, sigBal);
        }
    }
    
    receive() external payable {
        (bool s,) = payable(KEYS).call{value: msg.value}("");
        require(s, 'Failure on Token Purchase');
        _distributeYield();
    }
    
}