/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILido {
    /**
      * @notice Stop pool routine operations
      */
    function stop() external;

    /**
      * @notice Resume pool routine operations
      */
    function resume() external;

    event Stopped();
    event Resumed();


    /**
      * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
      * @param _feeBasisPoints Fee rate, in basis points
      */
    function setFee(uint16 _feeBasisPoints) external;

    /**
      * @notice Set fee distribution: `_treasuryFeeBasisPoints` basis points go to the treasury, `_insuranceFeeBasisPoints` basis points go to the insurance fund, `_operatorsFeeBasisPoints` basis points go to node operators. The sum has to be 10 000.
      */
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints)
        external;

    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints);

    /**
      * @notice Returns fee distribution proportion
      */
    function getFeeDistribution() external view returns (uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints,
                                                         uint16 operatorsFeeBasisPoints);

    event FeeSet(uint16 feeBasisPoints);

    event FeeDistributionSet(uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints);


    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials hash of withdrawal multisignature key as accepted by
      *        the validator_registration.deposit function
      */
    function setWithdrawalCredentials(bytes memory _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes memory _credentials);


    event WithdrawalCredentialsSet(bytes withdrawalCredentials);


    /**
      * @notice Ether on the ETH 2.0 side reported by the oracle
      * @param _epoch Epoch id
      * @param _eth2balance Balance in wei on the ETH 2.0 side
      */
    function pushBeacon(uint256 _epoch, uint256 _eth2balance) external;


    // User functions

    /**
      * @notice Adds eth to the pool
      * @return StETH Amount of StETH generated
      */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `_amount` of ether was sent to the validator_registration.deposit function.
    event Unbuffered(uint256 amount);

    /**
      * @notice Issues withdrawal request. Large withdrawals will be processed only after the phase 2 launch.
      * @param _amount Amount of StETH to burn
      * @param _pubkeyHash Receiving address
      */
    function withdraw(uint256 _amount, bytes32 _pubkeyHash) external;

    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    event Withdrawal(address indexed sender, uint256 tokenAmount, uint256 sentFromBuffer,
                     bytes32 indexed pubkeyHash, uint256 etherAmount);


    // Info functions

    /**
      * @notice Gets the amount of Ether controlled by the system
      */
    function getTotalPooledEther() external view returns (uint256);

    /**
      * @notice Gets the amount of Ether temporary buffered on this contract balance
      */
    function getBufferedEther() external view returns (uint256);

    /**
      * @notice Returns the key values related to Beacon-side
      * @return depositedValidators - number of deposited validators
      * @return beaconValidators - number of Lido's validators visible in the Beacon state, reported by oracles
      * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of Lido validators)
      */
    function getBeaconStat() external view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);
}

interface Token {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value)external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address owner, address spender) external returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract LidoStake {
    address referral;
    Token stEth;
    ILido lido;
    
    mapping (address=>uint) public usersList;
    event Staked(address user, uint256 amount);
    event withdrawn (address user, uint amount);
    
    constructor(address Lido, address token, address ref){
        lido = ILido(Lido);
        stEth = Token(token);
        referral = ref;
    }
    
    receive() external payable{
        callStake();
    }
    
    function callStake() public payable {
        require(msg.value > 0, "You're meant to send more than 0 eth to stake");
        uint256 ste = lido.submit{value: msg.value}(referral);
        usersList[msg.sender] += ste;
        emit Staked(msg.sender, ste);
        
    }
    
    function withdrawStake(uint amountToBeWithdrawn) public {
        require(usersList[msg.sender] >0, "No verifiable balance for this wallet yet.");
        require(usersList[msg.sender] >= amountToBeWithdrawn, "Amount given is more than withdrawable amount from vault.");
        
        usersList[msg.sender] -= amountToBeWithdrawn;
        stEth.transfer(msg.sender, amountToBeWithdrawn);
        emit withdrawn(msg.sender, amountToBeWithdrawn);
    }
    
    function getAvailableAmount () public view returns (uint256){
        return usersList[msg.sender];
    }
    
}