//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import {Datatypes} from "../Libraries/Datatypes.sol";

interface IPools {
    event newPoolCreated(
        string _poolName,
        address indexed _owner,
        string symbol,
        uint256 _targetPrice,
        uint256 _timestamp
    );
    event verified(
        string  _poolName,
        address _sender,
        uint256 _timestamp
    );
    event newDeposit(
        string _poolName,
        address _sender,
        uint256 _amount,
        uint256 _timestamp
    );
    event totalPoolDeposit(
        string _poolName,
        uint256 _amount,
        uint256 _timestamp
    );
    event totalUserScaledDeposit(
        string _poolName,
        address indexed _sender,
        uint256 _amount,
        uint256 _timestamp
    );
    event totalPoolScaledDeposit(
        string _poolName,
        uint256 _amount,
        uint256 _timestamp
    );
    event newWithdrawal(
        string _poolName,
        address indexed _sender,
        uint256 _amount,
        uint256 _timestamp
    );

    function deposit(
        string calldata _poolName,
        uint256 _amount,
        address _sender
    ) external;

    function withdraw(
        string calldata _poolName,
        uint256 _amount,
        address _sender
    ) external returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;

library Datatypes {
    struct TokenData {
        string symbol;
        address token;
        address aToken;
        address priceFeed;
        uint8 decimals;
    }

    struct PrivatePool {
        string poolName;
        string symbol;
        bool active;
        address owner;
        address accountAddress;
        uint256 targetPrice;
        uint256 poolScaledAmount;
        uint256 rewardScaledAmount;
        mapping(address => bool) verified;
        mapping(bytes => bool) signatures;
        mapping(address => uint256) userScaledDeposits;
    }

    struct PublicPool {
        string poolName;
        string symbol;
        bool active;
        address owner;
        address accountAddress;
        uint256 targetPrice;
        uint256 poolScaledAmount;
        uint256 rewardScaledAmount;
        mapping(address => uint256) userScaledDeposits;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

library ScaledMath 
{
    using SafeMath for uint256;

    function realToScaled(
        uint256 _realAmount,
        uint256 _reserveNormalizedIncome
    ) 
        external 
        pure 
        returns (uint256) 
    {
        return (_realAmount.mul(10**27)).div(_reserveNormalizedIncome);
    }

    function scaledToReal(
        uint256 _scaledAmount,
        uint256 _reserveNormalizedIncome
    )
        external
        pure
        returns (uint256)
    {
        return (_scaledAmount.mul(_reserveNormalizedIncome)).div(10**27);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ILendingPool, ILendingPoolAddressesProvider } from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import { Datatypes } from '../Libraries/Datatypes.sol';
import { ScaledMath } from '../Libraries/ScaledMath.sol';
import './DonationPools.sol';
import './PrivatePools.sol';
import './PublicPools.sol';


contract Comptroller is Ownable
{
	using Datatypes for *;
	using SafeMath for uint256;
    using ScaledMath for uint256;

	address public donationPoolsContract;
	address public privatePoolsContract;
    address public publicPoolsContract;
	address lendingPoolAddressProvider = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
	mapping(string => Datatypes.TokenData) public tokenData;

    event newTokenAdded(string _symbol, address _token, address _aToken);

    function setPoolAddresses(
        address _privatePoolsContract,
        address _publicPoolsContract,
        address _donationPoolsContract
    ) external onlyOwner 
    {
        privatePoolsContract = _privatePoolsContract;
        publicPoolsContract = _publicPoolsContract;
        donationPoolsContract = _donationPoolsContract;
    }

    function addTokenData(
        string calldata _symbol,
        address _token,
        address _aToken,
        address _priceFeed,
        uint8 _decimals
    ) external onlyOwner 
    {
        require(
            keccak256(abi.encode(tokenData[_symbol].symbol)) != keccak256(abi.encode(_symbol)),
            "Token data already present !"
        );

        Datatypes.TokenData storage newTokenData = tokenData[_symbol];

        newTokenData.symbol = _symbol;
        newTokenData.token = _token;
        newTokenData.aToken = _aToken;
        newTokenData.priceFeed = _priceFeed;
        newTokenData.decimals = _decimals;

        emit newTokenAdded(_symbol, _token, _aToken);
    }

    function depositERC20(
        string calldata _poolName,
        uint256 _amount,
        bool _typePrivate // If false => PublicPool
    ) external 
    {
        string memory tokenSymbol;

        if(_typePrivate)
            (,tokenSymbol,,,,,,) = PrivatePools(privatePoolsContract).poolNames(_poolName);
        else
            (,tokenSymbol,,,,,,) = PublicPools(publicPoolsContract).poolNames(_poolName);

        Datatypes.TokenData memory poolTokenData = tokenData[tokenSymbol];
        IERC20 token = IERC20(poolTokenData.token);
        address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();

        // Checking if user has allowed this contract to spend
        require(
            _amount <= token.allowance(msg.sender, address(this)),
            "Amount exceeds allowance limit !"
        );
        // Transfering tokens into this account
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Unable to transfer tokens to comptroller !"
        );
        // Transfering into Lending Pool
        require(
            token.approve(lendingPool, _amount), 
            "Approval failed !"
        );

        ILendingPool(lendingPool).deposit(
            poolTokenData.token,
            _amount,
            address(this),
            0
        );

		uint256 newScaledDeposit = _amount.realToScaled(getReserveIncome(tokenSymbol));

		uint256 donationAmount = DonationPools(donationPoolsContract).donate(
			newScaledDeposit,
			tokenSymbol
		);

        if(_typePrivate)
        {
            PrivatePools(privatePoolsContract).deposit(
                _poolName,
                newScaledDeposit.sub(donationAmount),
                msg.sender
            );
        }
        else
        {
            PublicPools(publicPoolsContract).deposit(
                _poolName,
                newScaledDeposit.sub(donationAmount),
                msg.sender
            );
        }
	}

	function withdrawERC20(
		string calldata _poolName, 
		uint256 _amount,
		bool _typePrivate // If false => PublicPool 
	) external
	{
		string memory tokenSymbol;
		bool penalty;
        uint256 withdrawalAmount;
        
		
        if(_typePrivate)
		{
			withdrawalAmount = PrivatePools(privatePoolsContract).withdraw(
				_poolName, 
				_amount,
				msg.sender
			);
			(,tokenSymbol,penalty,,,,,) = PrivatePools(privatePoolsContract).poolNames(_poolName);
		}
		else
		{
			withdrawalAmount = PublicPools(publicPoolsContract).withdraw(
				_poolName, 
				_amount,
				msg.sender
			);
			(,tokenSymbol,penalty,,,,,) = PublicPools(publicPoolsContract).poolNames(_poolName);
		}
		
        Datatypes.TokenData memory poolTokenData = tokenData[tokenSymbol];
		address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();
        
		// If target price of the pool wasn't achieved, take out the donation amount too.
		if(penalty)
		{
			uint256 donationAmount = DonationPools(donationPoolsContract).donate(
				withdrawalAmount,
				tokenSymbol
			);
			withdrawalAmount = withdrawalAmount.sub(donationAmount);
		}
		
		// Till now withdrawalAmount was scaled down.
        withdrawalAmount = withdrawalAmount.scaledToReal(getReserveIncome(tokenSymbol));

		// Approving aToken pool
        require(
            IERC20(poolTokenData.aToken).approve(lendingPool, withdrawalAmount),
            "aToken approval failed !"
        );

        // Redeeming the aTokens
        ILendingPool(lendingPool).withdraw(
            poolTokenData.token,
            withdrawalAmount,
            msg.sender
        );
	}

	// This function is for the Recipients (NGOs)
	function withdrawDonation(string calldata _tokenSymbol) external
	{
		Datatypes.TokenData memory poolTokenData = tokenData[_tokenSymbol];
		address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();
		uint256 withdrawalAmount = DonationPools(donationPoolsContract).withdraw(msg.sender, _tokenSymbol);
	
		withdrawalAmount = withdrawalAmount.scaledToReal(getReserveIncome(_tokenSymbol));

        require(
            IERC20(poolTokenData.aToken).approve(lendingPool, withdrawalAmount),
            "aToken approval failed !"
        );

        // Redeeming the aTokens
        ILendingPool(lendingPool).withdraw(
            poolTokenData.token,
            withdrawalAmount,
            msg.sender
        );
	}

    function getReserveIncome(string memory _symbol) public view returns(uint256)
    {
        address lendingPool = ILendingPoolAddressesProvider(lendingPoolAddressProvider).getLendingPool();

        return ILendingPool(lendingPool).getReserveNormalizedIncome(tokenData[_symbol].token);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "../Interfaces/IPools.sol";
import "./Comptroller.sol";

/***
 * Donation pool for charities/NGOs to withdraw donations
 * @author Chinmay Vemuri
 */
contract DonationPools is Ownable {
    using SafeMath for uint256;

    struct Recipient {
        string organisationName;
        bool active;
        mapping(string => uint256) latestWithdrawalTimestamp;
    }

    address comptrollerContract;
    uint256 constant DONATION_FEE = 100; // Represents basis points
    uint256 numRecipients;
    mapping(address => Recipient) public recipients;
    mapping(string => uint256) public donationAmount;

    event newDonation(
        uint256 _donationAmount,
        string indexed _tokenSymbol,
        uint256 _timestamp
    );
    event newRecipientAdded(
        address indexed _recipient,
        string indexed _organisationName,
        uint256 _timestamp
    );
    event recipientReactivated(
        address indexed _recipient,
        string indexed _organisationName,
        uint256 _timestamp
    );
    event recipientDeactivated(
        address indexed _recipient,
        string indexed _organisationName,
        uint256 _timestamp
    );
    event newDonationWithdrawal(
        address indexed _recipient,
        string indexed _organisationName,
        uint256 _timestamp
    );

    modifier onlyComptroller {
        require(
            msg.sender == comptrollerContract, 
            "Unauthorized access"
        );
        _;
    }

    constructor(address _comptrollerContract) public
    {
        comptrollerContract = _comptrollerContract;
    }

    function addRecipient(address _recipient, string calldata _organisationName)
        external
        onlyOwner
    {
        Recipient storage newRecipient = recipients[_recipient];

        newRecipient.organisationName = _organisationName;
        newRecipient.active = true;
        ++numRecipients;

        emit newRecipientAdded(
            _recipient,
            newRecipient.organisationName,
            block.timestamp
        );
    }

    function reActivateRecipient(address _recipient) external onlyOwner {
        require(
            recipients[_recipient].active == false,
            "Recipient already activated"
        );

        recipients[_recipient].active = true;
        ++numRecipients;

        emit recipientReactivated(
            _recipient, 
            recipients[_recipient].organisationName, 
            block.timestamp
        );
    }

    function deactivateRecipient(address _recipient) external onlyOwner {
        require(
            recipients[_recipient].active == true,
            "Recipient already deactivated"
        );

        recipients[_recipient].active = false;
        --numRecipients;

        emit recipientDeactivated(
            _recipient,
            recipients[_recipient].organisationName,
            block.timestamp
        );
    }

    function donate(uint256 _amount, string calldata _tokenSymbol)
        external
        onlyComptroller
        returns (uint256)
    {
        uint256 collectionAmount = (_amount.mul(DONATION_FEE)).div(10**4);

        donationAmount[_tokenSymbol] = donationAmount[_tokenSymbol].add(
            collectionAmount
        );

        emit newDonation(collectionAmount, _tokenSymbol, block.timestamp);

        return collectionAmount;
    }

    function withdraw(address _recipient, string calldata _tokenSymbol)
        external
        onlyComptroller
        returns (uint256)
    {
        require(recipients[_recipient].active, "Invalid/Deactivated recipient");
        require(
            block.timestamp.sub(
                recipients[_recipient].latestWithdrawalTimestamp[_tokenSymbol]
            ) >= 4 weeks,
            "Donation share already redeemed"
        );

        uint256 withdrawalScaledAmount = donationAmount[_tokenSymbol].div(numRecipients);
        recipients[_recipient].latestWithdrawalTimestamp[_tokenSymbol] = block.timestamp;

        emit newDonationWithdrawal(
            msg.sender,
            recipients[_recipient].organisationName,
            block.timestamp
        );

        return withdrawalScaledAmount;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/cryptography/ECDSA.sol";
import { ILendingPool, ILendingPoolAddressesProvider } from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import "@aave/protocol-v2/contracts/interfaces/IScaledBalanceToken.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { Datatypes } from '../Libraries/Datatypes.sol';
import { ScaledMath } from '../Libraries/ScaledMath.sol';
import './Comptroller.sol';
import '../Interfaces/IPools.sol';

/***
 * @notice Private pools creation and functions related to private pools.
 * @author Chinmay Vemuri
 */
contract PrivatePools is IPools, Ownable 
{
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using ScaledMath for uint256;
    using Datatypes for *;

    address lendingPoolAddressProvider = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
    address comptrollerContract;
    uint256 constant REWARD_FEE_PER = 400; // Fee percentage (basis points) given to Pool members.
    mapping(string => Datatypes.PrivatePool) public poolNames;


    modifier checkPoolName(string calldata _poolName)
    {
        require(
            keccak256(abi.encode(_poolName)) != keccak256(abi.encode('')),
            "Pool name can't be empty !"
        );
        _;
    }

    modifier onlyVerified(string calldata _poolName, address _sender) 
    {
        require(
            poolNames[_poolName].verified[_sender],
            "User not verified by the pool"
        );
        _;
    }

    modifier onlyComptroller 
    {
        require(
            msg.sender == comptrollerContract, 
            "Unauthorized access"
        );
        _;
    }

    constructor(address _comptrollerContract) public
    {
        comptrollerContract = _comptrollerContract;
    }

    function createPool(
        string calldata _symbol,
        string calldata _poolName,
        uint256 _targetPrice,
        address _poolAccountAddress // For invitation purpose
    ) external checkPoolName(_poolName)
    {
        (, , , address priceFeed, uint8 decimals) = Comptroller(comptrollerContract).tokenData(_symbol);

        require(
            priceFeed != address(0),
            "Token/pricefeed doesn't exist"
        );  
        require(
            keccak256(abi.encode(_symbol)) != keccak256(abi.encode('')),
            "Token symbol can't be empty !"
        );
        require(
            keccak256(abi.encode(poolNames[_poolName].poolName)) != keccak256(abi.encode(_poolName)),
            "Pool name already taken !"
        );
        require(
            _targetPrice.mul(10**uint256(decimals)) > uint256(priceFeedData(priceFeed)),
            "Target price is lesser than current price"
        );

        Datatypes.PrivatePool storage newPool = poolNames[_poolName];

        newPool.poolName = _poolName;
        newPool.owner = msg.sender;
        newPool.symbol = _symbol;
        newPool.accountAddress = _poolAccountAddress;
        newPool.targetPrice = _targetPrice;
        newPool.active = true;
        newPool.poolScaledAmount = 0;
        newPool.verified[msg.sender] = true;

        emit newPoolCreated(
            _poolName,
            msg.sender,
            _symbol,
            _targetPrice,
            block.timestamp
        );
    }

    function verifyPoolAccess(
        string calldata _poolName,
        bytes32 _messageHash,
        bytes calldata _signature
    ) external checkPoolName(_poolName)
    {
        Datatypes.PrivatePool storage pool = poolNames[_poolName];

        require(
            pool.active,
            "Pool not active !"
        );
        require(
            _messageHash.recover(_signature) == poolNames[_poolName].accountAddress,
            "Verification failed"
        );
        require(
            !pool.signatures[_signature],
            "Unauthorized access: Reusing signature"
        );

        pool.verified[msg.sender] = true;
        pool.signatures[_signature] = true;

        emit verified(_poolName, msg.sender, block.timestamp);
    }

    function deposit(
        string calldata _poolName,
        uint256 _scaledAmount,
        address _sender
    ) 
        external 
        override
        onlyVerified(_poolName, _sender) 
        onlyComptroller
        checkPoolName(_poolName) 
    {
        Datatypes.PrivatePool storage pool = poolNames[_poolName];

        if(pool.active)
            checkPoolBreak(_poolName);

        require(
            poolNames[_poolName].active, 
            "Pool not active !"
        );

        pool.userScaledDeposits[_sender] = pool.userScaledDeposits[_sender].add(_scaledAmount);
        pool.poolScaledAmount = pool.poolScaledAmount.add(_scaledAmount);

        emit newDeposit(
            _poolName, 
            _sender, 
            _scaledAmount, 
            block.timestamp
        );
        emit totalPoolDeposit(
            _poolName,
           pool.poolScaledAmount.scaledToReal(
                Comptroller(comptrollerContract).getReserveIncome(pool.symbol)
            ),
            block.timestamp
        );
        emit totalUserScaledDeposit(
            _poolName,
            _sender,
            pool.userScaledDeposits[_sender],
            block.timestamp
        );
        emit totalPoolScaledDeposit(
            _poolName,
            pool.poolScaledAmount,
            block.timestamp
        );
    }

    function withdraw(
        string calldata _poolName,
        uint256 _amount,
        address _sender
    )
        external
        override
        onlyComptroller
        onlyVerified(_poolName, _sender)
        checkPoolName(_poolName)
        returns(uint256)
    {
        if(poolNames[_poolName].active)
            checkPoolBreak(_poolName);

        // Converting the given amount to scaled amount
        _amount = _amount.realToScaled(Comptroller(comptrollerContract).getReserveIncome(poolNames[_poolName].symbol));
        (_amount == 0)? _amount = poolNames[_poolName].userScaledDeposits[_sender]: _amount;
        
        require(
            poolNames[_poolName].userScaledDeposits[_sender] >= _amount,
            "Amount exceeds user's reward amount !"
        );

        /**
         * Reward = UD*RA/PD
         * RA = RA - Reward
         * withdrawalFeeAmount = (UD + Reward)*(WF/10**4)
         * poolReward = withdrawalFeeAmount*4/5
         * RA = RA + poolRewardAmount
         * nominalFee = withdrawalFeeAmount - poolReward
         */

        _amount = calculateWithdrawalAmount(_poolName, _amount, _sender);

        emit newWithdrawal(
            _poolName,
            _sender,
            _amount,
            block.timestamp
        );

        // Converting scaled amount to real amount
        _amount = _amount.scaledToReal(Comptroller(comptrollerContract).getReserveIncome(poolNames[_poolName].symbol));

        emit newWithdrawal(
            _poolName,
            _sender,
            _amount,
            block.timestamp
        );
        emit totalPoolDeposit(
            _poolName,
            _amount, 
            block.timestamp
        );
        emit totalUserScaledDeposit(
            _poolName,
            _sender,
            poolNames[_poolName].userScaledDeposits[_sender],
            block.timestamp
        );
        emit totalPoolScaledDeposit(
            _poolName,
            poolNames[_poolName].poolScaledAmount,
            block.timestamp
        );

        return (_amount);
    }

    function checkPoolBreak(string calldata _poolName) internal
    {
        Datatypes.PrivatePool storage pool = poolNames[_poolName];
        (, , , address priceFeed, uint8 decimals) = Comptroller(comptrollerContract).tokenData(pool.symbol);

        
        if (
            pool.active &&
            pool.targetPrice.mul(10**uint256(decimals)) <= uint256(priceFeedData(priceFeed))
        ) { pool.active = false; }
    }

    function priceFeedData(address _aggregatorAddress)
        internal
        view
        returns (int256)
    {
        (, int256 price, , , ) = AggregatorV3Interface(_aggregatorAddress).latestRoundData();

        return price;
    }

    function calculateWithdrawalAmount(
        string calldata _poolName,
        uint256 _amount, // This is scaled amount
        address _sender
    ) internal returns(uint256) 
    {
        uint256 rewardScaledAmount = (_amount.mul(poolNames[_poolName].rewardScaledAmount)).div(poolNames[_poolName].poolScaledAmount);
        poolNames[_poolName].rewardScaledAmount = poolNames[_poolName].rewardScaledAmount.sub(rewardScaledAmount);
        poolNames[_poolName].poolScaledAmount = poolNames[_poolName].poolScaledAmount.sub(_amount);
        poolNames[_poolName].userScaledDeposits[_sender] = poolNames[_poolName].userScaledDeposits[_sender].sub(_amount);

        if(poolNames[_poolName].active) 
        {
            uint256 withdrawalFeeAmount = ((_amount.add(rewardScaledAmount)).mul(REWARD_FEE_PER))
                                            .div(10**4);

            _amount = _amount.sub(withdrawalFeeAmount);
            poolNames[_poolName].rewardScaledAmount = poolNames[_poolName].rewardScaledAmount
                                                        .add(withdrawalFeeAmount);
        }

        return _amount;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ILendingPool, ILendingPoolAddressesProvider } from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { Datatypes } from '../Libraries/Datatypes.sol';
import { ScaledMath } from '../Libraries/ScaledMath.sol';
import './Comptroller.sol';
import '../Interfaces/IPools.sol';

/***
 * Public pool creation and functions related to public pools.
 * These pools can only be created by developers
 * @author Chinmay Vemuri
 */

contract PublicPools is IPools, Ownable 
{
    using SafeMath for uint256;
    using ScaledMath for uint256;
    using Datatypes for *;


    address lendingPoolAddressProvider = 0x88757f2f99175387aB4C6a4b3067c77A695b0349;
    address comptrollerContract;
    uint256 constant REWARD_FEE_PER = 400; // Fee percentage (basis points) given to Pool members.
    mapping(string => Datatypes.PublicPool) public poolNames;


    modifier checkPoolName(string calldata _poolName)
    {
        require(
            keccak256(abi.encode(_poolName)) != keccak256(abi.encode('')),
            "Pool name can't be empty !"
        );
        _;
    }

    modifier onlyComptroller 
    {
        require(msg.sender == comptrollerContract, "Unauthorized access");
        _;
    }


    constructor(address _comptrollerContract) public
    {
        comptrollerContract = _comptrollerContract;
    }

    function createPool(
        string calldata _symbol,
        string calldata _poolName,
        uint256 _targetPrice
    ) 
        external
        checkPoolName(_poolName) 
        onlyOwner 
    {
        require(
            keccak256(abi.encode(_symbol)) != keccak256(abi.encode("")),
            "Token symbol can't be empty !"
        );

        (, , , address priceFeed, uint8 decimals) = Comptroller(comptrollerContract).tokenData(_symbol);

        require(
            priceFeed != address(0),
            "Token/pricefeed doesn't exist"
        );
        require(
            keccak256(abi.encode(poolNames[_poolName].poolName)) != keccak256(abi.encode(_poolName)),
            "Pool name already taken !"
        );
        require(
            _targetPrice.mul(10**uint256(decimals)) > uint256(priceFeedData(priceFeed)),
            "Target price is lesser than current price"
        );

        Datatypes.PublicPool storage newPool = poolNames[_poolName];

        newPool.poolName = _poolName;
        newPool.owner = msg.sender;
        newPool.symbol = _symbol;
        newPool.targetPrice = _targetPrice;
        newPool.active = true;
        newPool.poolScaledAmount = 0;

        emit newPoolCreated(
            _poolName,
            msg.sender,
            _symbol,
            _targetPrice,
            block.timestamp
        );
    }

    function deposit(
        string calldata _poolName,
        uint256 _scaledAmount,
        address _sender
    ) 
        external 
        override 
        checkPoolName(_poolName)
        onlyComptroller 
    {
        Datatypes.PublicPool storage pool = poolNames[_poolName];

        if(pool.active)
            checkPoolBreak(_poolName);

        require(
            poolNames[_poolName].active, 
            "Pool not active !"
        );

        pool.userScaledDeposits[_sender] = pool.userScaledDeposits[_sender].add(_scaledAmount);
        pool.poolScaledAmount = pool.poolScaledAmount.add(_scaledAmount);

        emit newDeposit(
            _poolName, 
            _sender, 
            _scaledAmount, 
            block.timestamp
        );
        emit totalPoolDeposit(
            _poolName,
           pool.poolScaledAmount.scaledToReal(
                Comptroller(comptrollerContract).getReserveIncome(pool.symbol)
            ),
            block.timestamp
        );
        emit totalUserScaledDeposit(
            _poolName,
            _sender,
            pool.userScaledDeposits[_sender],
            block.timestamp
        );
        emit totalPoolScaledDeposit(
            _poolName,
            pool.poolScaledAmount,
            block.timestamp
        );
    }

    function withdraw(
        string calldata _poolName,
        uint256 _amount,
        address _sender
    )
        external
        override
        onlyComptroller
        checkPoolName(_poolName)
        returns (uint256)
    {
        if(poolNames[_poolName].active)
            checkPoolBreak(_poolName);

        // Converting the given amount to scaled amount
        uint256 scaledAmount = _amount.realToScaled(Comptroller(comptrollerContract).getReserveIncome(poolNames[_poolName].symbol));
        (scaledAmount == 0)? scaledAmount = poolNames[_poolName].userScaledDeposits[_sender]: scaledAmount;
        
        require(
            poolNames[_poolName].userScaledDeposits[_sender] >= scaledAmount,
            "Amount exceeds user's reward amount !"
        );
        /**
         * Reward = UD*RA/PD
         * RA = RA - Reward
         * withdrawalFeeAmount = (UD + Reward)*(WF/10**4)
         * poolReward = withdrawalFeeAmount*4/5
         * RA = RA + poolRewardAmount
         * nominalFee = withdrawalFeeAmount - poolReward
         */

        scaledAmount = calculateWithdrawalAmount(_poolName, scaledAmount, _sender);
        _amount = scaledAmount.scaledToReal(Comptroller(comptrollerContract).getReserveIncome(poolNames[_poolName].symbol));

        emit newWithdrawal(
            _poolName,
            _sender,
            scaledAmount,
            block.timestamp
        );
        emit totalPoolDeposit(
            _poolName,
            _amount, 
            block.timestamp
        );
        emit totalUserScaledDeposit(
            _poolName,
            _sender,
            poolNames[_poolName].userScaledDeposits[_sender],
            block.timestamp
        );
        emit totalPoolScaledDeposit(
            _poolName,
            poolNames[_poolName].poolScaledAmount,
            block.timestamp
        );

        return (_amount);
    }

    function checkPoolBreak(string calldata _poolName) internal
    {
        Datatypes.PublicPool storage pool = poolNames[_poolName];
        (, , , address priceFeed, uint8 decimals) = Comptroller(comptrollerContract).tokenData(pool.symbol);

        if (
            pool.active &&
            pool.targetPrice.mul(10**uint256(decimals)) <= uint256(priceFeedData(priceFeed))
        ) { pool.active = false; }
    }

    function calculateWithdrawalAmount(
        string calldata _poolName,
        uint256 _amount, // This is scaled amount
        address _sender
    ) internal returns(uint256) 
    {
        uint256 rewardScaledAmount = (_amount.mul(poolNames[_poolName].rewardScaledAmount)).div(poolNames[_poolName].poolScaledAmount);
        poolNames[_poolName].rewardScaledAmount = poolNames[_poolName].rewardScaledAmount.sub(rewardScaledAmount);
        poolNames[_poolName].poolScaledAmount = poolNames[_poolName].poolScaledAmount.sub(_amount); // Test whether only _amount needs to be subtracted.
        poolNames[_poolName].userScaledDeposits[_sender] = poolNames[_poolName].userScaledDeposits[_sender].sub(_amount);

        if(poolNames[_poolName].active) 
        {
            uint256 withdrawalFeeAmount = ((_amount.add(rewardScaledAmount)).mul(REWARD_FEE_PER))
                                            .div(10**4);

            _amount = _amount.sub(withdrawalFeeAmount);
            poolNames[_poolName].rewardScaledAmount = poolNames[_poolName].rewardScaledAmount
                                                        .add(withdrawalFeeAmount);
        }

        return _amount;
    }

    function priceFeedData(address _aggregatorAddress)
        internal
        view
        returns (int256)
    {
        (, int256 price, , , ) = AggregatorV3Interface(_aggregatorAddress).latestRoundData();

        return price;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}