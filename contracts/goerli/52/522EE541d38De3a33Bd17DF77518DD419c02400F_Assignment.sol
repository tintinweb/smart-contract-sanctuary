// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;
import "./interfaces/ILido.sol";
import "./interfaces/ISTETH.sol";

contract Assignment {

    mapping(address => uint) private balances;
    ILido public Lido;
    ISTETH public StEth;

    constructor(ILido _lido, ISTETH _iStEth) {
        Lido = ILido(_lido);
        StEth = ISTETH(_iStEth);
    }

    function depositToLido(address referrer) public payable {
        uint256 value = Lido.submit{value:msg.value}(referrer);
        balances[msg.sender] += value;
    }

    function withdrawStETH(uint256 amount) public {
        require(amount <= balances[msg.sender],"Not enough balance");
        balances[msg.sender] -= amount;
        StEth.transfer(msg.sender, amount);
    }
}

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


/**
  * @title A liquid version of ETH 2.0 native token
  *
  * ERC20 token which supports stop/resume mechanics. The token is operated by `ILido`.
  *
  * Since balances of all token holders change when the amount of total controlled Ether
  * changes, this token cannot fully implement ERC20 standard: it only emits `Transfer`
  * events upon explicit transfer between holders. In contrast, when Lido oracle reports
  * rewards, no Transfer events are generated: doing so would require emitting an event
  * for each token holder and thus running an unbounded loop.
  */
interface ISTETH /* is IERC20 */ {
    function totalSupply() external view returns (uint256);

    /**
      * @notice Stop transfers
      */
    function stop() external;

    /**
      * @notice Resume transfers
      */
    function resume() external;

    /**
      * @notice Returns true if the token is stopped
      */
    function isStopped() external view returns (bool);

    event Stopped();
    event Resumed();

    /**
    * @notice Increases shares of a given address by the specified amount. Called by Lido
    *         contract in two cases: 1) when a user submits an ETH1.0 deposit; 2) when
    *         ETH2.0 rewards are reported by the oracle. Upon user deposit, Lido contract
    *         mints the amount of shares that corresponds to the submitted Ether, so
    *         token balances of other token holders don't change. Upon rewards report,
    *         Lido contract mints new shares to distribute fee, effectively diluting the
    *         amount of Ether that would otherwise correspond to each share.
    *
    * @param _to Receiver of new shares
    * @param _sharesAmount Amount of shares to mint
    * @return The total amount of all holders' shares after new shares are minted
    */
    function mintShares(address _to, uint256 _sharesAmount) external returns (uint256);

    /**
      * @notice Burn is called by Lido contract when a user withdraws their Ether.
      * @param _account Account which tokens are to be burnt
      * @param _sharesAmount Amount of shares to burn
      * @return The total amount of all holders' shares after the shares are burned
      */
    function burnShares(address _account, uint256 _sharesAmount) external returns (uint256);


    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function getTotalShares() external view returns (uint256);

    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);
}

// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


/**
  * @title Liquid staking pool
  *
  * For the high-level description of the pool operation please refer to the paper.
  * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
  * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
  * only a small portion (buffer) of it.
  * It also mints new tokens for rewards generated at the ETH 2.0 side.
  */
interface ILido {
    /**
     * @dev From ISTETH interface, because "Interfaces cannot inherit".
     */
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

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
      *        the deposit_contract.deposit function
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() external view returns (bytes memory);


    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);


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

    // The `_amount` of ether was sent to the deposit_contract.deposit function.
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