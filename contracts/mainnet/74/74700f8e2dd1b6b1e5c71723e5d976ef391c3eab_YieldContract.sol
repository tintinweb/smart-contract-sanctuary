// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.2;

// Importing libraries
import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Yield Contract
 * @notice Contract to create yield contracts for users
 */

/**
 * TO NOTE
 * @notice Store collateral and provide interest MXX or burn MXX
 * @notice Interest (contractFee, penaltyFee etc) is always represented 10 power 6 times the actual value
 * @notice Note that only 4 decimal precision is allowed for interest
 * @notice If interest is 5%, then value to input is 0.05 * 10 pow 6 = 5000
 * @notice mFactor or mintFactor is represented 10 power 18 times the actual value.
 * @notice If value of 1 ETH is 380 USD, then mFactor of ETH is (380 * (10 power 18))
 * @notice Collateral should always be in its lowest denomination (based on the coin or Token)
 * @notice If collateral is 6 USDT, then value is 6 * (10 power 6) as USDT supports 6 decimals
 * @notice startTime and endTime are represented in Unix time
 * @notice tenure for contract is represented in days (90, 180, 270) etc
 * @notice mxxToBeMinted or mxxToBeMinted is always in its lowest denomination (8 decimals)
 * @notice For e.g if mxxToBeMinted = 6 MXX, then actual value is 6 * (10 power 8)
 */

contract YieldContract is Ownable, ReentrancyGuard {
    // Using SafeERC20 for ERC20
    using SafeERC20 for ERC20;

    // Using SafeMath Library to prevent integer overflow
    using SafeMath for uint256;

    // Using Address library for ERC20 contract checks
    using Address for address;

    /**
     * DEFINING VARIABLES
     */

    /**
     * @dev - Array to store valid ERC20 addresses
     */
    address[] public erc20List;

    /**
     * @dev - A struct to store ERC20 details
     * @notice symbol - The symbol/ ticker symbol of ERC20 contract
     * @notice isValid - Boolean variable indicating if the ERC20 is valid to be used for yield contracts
     * @notice noContracts - Integer indicating the number of contracts associated with it
     * @notice mFactor - Value of a coin/token in USD * 10 power 18
     */
    struct Erc20Details {
        string symbol;
        bool isValid;
        uint64 noContracts;
        uint256 mFactor;
    }

    /**
     * @dev - A mapping to map ERC20 addresses to its details
     */
    mapping(address => Erc20Details) public erc20Map;

    /**
     * @dev - Array to store user created yield contract IDs
     */
    bytes32[] public allContracts;

    /**
     * @dev - A enum to store yield contract status
     */
    enum Status {
        Inactive, 
        Active, 
        OpenMarket, 
        Claimed, 
        Destroyed
    }

    /**
     * @dev - A enum to switch set value case
     */
    enum ParamType {
        ContractFee,
        MinEarlyRedeemFee,
        MaxEarlyRedeemFee,
        TotalAllocatedMxx
    }

    /**
     * @dev - A struct to store yield contract details
     * @notice contractOwner - The owner of the yield contract
     * @notice tokenAddress - ERC20 contract address (if ETH then ZERO_ADDRESS)
     * @notice startTime - Start time of the yield contract (in unix timestamp)
     * @notice endTime - End time of the yield contract (in unix timestamp)
     * @notice tenure - The agreement tenure in days
     * @notice contractStatus - The status of a contract (can be Inactive/Active/OpenMarket/Claimed/Destroyed)
     * @notice collateral - Value of collateral (multiplied by 10 power 18 to handle decimals)
     * @notice mxxToBeMinted - The final MXX token value to be returned to the contract owner
     * @notice interest - APY or Annual Percentage Yield (returned from tenureApyMap)
     */
    struct ContractDetails {
        address contractOwner;
        uint48 startTime;
        uint48 endTime;
        address tokenAddress;
        uint16 tenure;
        uint64 interest;
        Status contractStatus;
        uint256 collateral;
        uint256 mxxToBeMinted;
    }

    /**
     * @dev - A mapping to map contract IDs to their details
     */
    mapping(bytes32 => ContractDetails) public contractMap;

    /**
     * @dev - A mapping to map tenure in days to apy (Annual Percentage Yield aka interest rate)
     * Percent rate is multiplied by 10 power 6. (For e.g. if 5% then value is 0.05 * 10 power 6)
     */
    mapping(uint256 => uint64) public tenureApyMap;

    /**
     * @dev - Variable to store contract fee
     * If 10% then value is 0.1 * 10 power 6
     */
    uint64 public contractFee;

    /**
     * @dev - Constant variable to store Official MXX ERC20 token address
     */
    address public constant MXX_ADDRESS = 0x8a6f3BF52A26a21531514E23016eEAe8Ba7e7018;

    /**
     * @dev - Constant address to store the Official MXX Burn Address
     */
    address public constant BURN_ADDRESS = 0x19B292c1a84379Aab41564283e7f75bF20e45f91;

    /**
     * @dev - Constant variable to store ETH address
     */
    address internal constant ZERO_ADDRESS = address(0);

    /**
     * @dev - Constant variable to store 10 power of 6
     */
    uint64 internal constant POW6 = 1000000;

    /**
     * @dev - Variable to store total allocated MXX for yield contracts
     */
    uint256 public totalAllocatedMxx;

    /**
     * @dev - Variable to total MXX minted from yield contracts
     */
    uint256 public mxxMintedFromContract;

    /**
     * @dev - Variables to store % of penalty / redeem fee fees
     * If min penalty / redeem fee is 5% then value is 0.05 * 10 power 6
     * If max penalty / redeem fee is 50% then value is 0.5 * 10 power 6
     */
    uint64 public minEarlyRedeemFee;
    uint64 public maxEarlyRedeemFee;

    /**
     * CONSTRUCTOR FUNCTION
     */

    constructor(uint256 _mxxmFactor) public Ownable() {
        // Setting default variables
        tenureApyMap[90] = 2 * POW6;
        tenureApyMap[180] = 4 * POW6;
        tenureApyMap[270] = 10 * POW6;
        contractFee = (8 * POW6) / 100;
        totalAllocatedMxx = 1000000000 * (10**8); // 1 billion initial Mxx allocated //
        minEarlyRedeemFee = (5 * POW6) / 100;
        maxEarlyRedeemFee = (5 * POW6) / 10;

        addErc20(MXX_ADDRESS, _mxxmFactor);
    }

    /**
     * DEFINE MODIFIER
     */

    /**
     * @dev Throws if address is a user address (except ZERO_ADDRESS)
     * @param _erc20Address - Address to be checked
     */

    modifier onlyErc20OrEth(address _erc20Address) {
        require(
            _erc20Address == ZERO_ADDRESS || Address.isContract(_erc20Address),
            "Not contract address"
        );
        _;
    }

    /**
     * @dev Throws if address in not in ERC20 list (check for mFactor and symbol)
     * @param _erc20Address - Address to be checked
     */

    modifier inErc20List(address _erc20Address) {
        require(
            erc20Map[_erc20Address].mFactor != 0 ||
                bytes(erc20Map[_erc20Address].symbol).length != 0,
            "Not in ERC20 list"
        );
        _;
    }

    /**
     * INTERNAL FUNCTIONS
     */

    /**
     * @dev This function will check the array for an element and retun the index
     * @param _inputAddress - Address for which the index has to be found
     * @param _inputAddressList - The address list to be checked
     * @return index - Index element indicating the position of the inputAddress inside the array
     * @return isFound - Boolean indicating if the element is present in the array or not
     * Access Control: This contract or derived contract
     */

    function getIndex(address _inputAddress, address[] memory _inputAddressList)
        internal
        pure
        returns (uint256 index, bool isFound)
    {
        // Enter loop
        for (uint256 i = 0; i < _inputAddressList.length; i++) {
            // If value matches, return index
            if (_inputAddress == _inputAddressList[i]) {
                return (i, true);
            }
        }

        // If no value matches, return false
        return (0, false);
    }

    /**
     * GENERAL FUNCTIONS
     */

    /**
     * @dev This function will set interest rate for the tenure in days
     * @param _tenure - Tenure of the agreement in days
     * @param _interestRate - Interest rate in 10 power 6 (If 5%, then value is 0.05 * 10 power 6)
     * @return - Boolean status - True indicating successful completion
     * Access Control: Only Owner
     */

    function setInterest(uint256 _tenure, uint64 _interestRate)
        public
        onlyOwner()
        returns (bool)
    {
        tenureApyMap[_tenure] = _interestRate;
        return true;
    }

    /**
     * @dev This function will set value based on ParamType
     * @param _parameter - Enum value indicating ParamType (0,1,2,3)
     * @param _value - Value to be set
     * @return - Boolean status - True indicating successful completion
     * Access Control: Only Owner
     */

    function setParamType(ParamType _parameter, uint256 _value)
        public
        onlyOwner()
        returns (bool)
    {
        if (_parameter == ParamType.ContractFee) {
            contractFee = uint64(_value);
        } else if (_parameter == ParamType.MinEarlyRedeemFee) {
            require(
                uint64(_value) <= maxEarlyRedeemFee,
                "Greater than max redeem fee"
            );
            minEarlyRedeemFee = uint64(_value);
        } else if (_parameter == ParamType.MaxEarlyRedeemFee) {
            require(
                uint64(_value) >= minEarlyRedeemFee,
                "Less than min redeem fee"
            );
            maxEarlyRedeemFee = uint64(_value);
        } else if (_parameter == ParamType.TotalAllocatedMxx) {
            require(
                _value >= mxxMintedFromContract,
                "Less than total mxx minted"
            );
            totalAllocatedMxx = _value;
        }
    }

    /**
     * SUPPORTED ERC20 ADDRESS FUNCTIONS
     */

    /**
     * @dev Adds a supported ERC20 address into the contract
     * @param _erc20Address - Address of the ERC20 contract
     * @param _mFactor - Mint Factor of the token (value of 1 token in USD * 10 power 18)
     * @return - Boolean status - True indicating successful completion
     * @notice - Access control: Only Owner
     */
    function addErc20(address _erc20Address, uint256 _mFactor)
        public
        onlyOwner()
        onlyErc20OrEth(_erc20Address)
        returns (bool)
    {
        // Check for existing contracts and validity. If condition fails, revert
        require(
            erc20Map[_erc20Address].noContracts == 0,
            "Token has existing contracts"
        );
        require(!erc20Map[_erc20Address].isValid, "Token already available");

        // Add token details and return true
        // If _erc20Address = ZERO_ADDRESS then it is ETH else ERC20
        erc20Map[_erc20Address] = Erc20Details(
            (_erc20Address == ZERO_ADDRESS)
                ? "ETH"
                : ERC20(_erc20Address).symbol(),
            true,
            0,
            _mFactor
        );

        erc20List.push(_erc20Address);
        return true;
    }

    /**
     * @dev Adds a list of supported ERC20 addresses into the contract
     * @param _erc20AddressList - List of addresses of the ERC20 contract
     * @param _mFactorList - List of mint factors of the token
     * @return - Boolean status - True indicating successful completion
     * @notice - The length of _erc20AddressList and _mFactorList must be the same
     * @notice - Access control: Only Owner
     */
    function addErc20List(
        address[] memory _erc20AddressList,
        uint256[] memory _mFactorList
    ) public onlyOwner() returns (bool) {
        // Check if the length of 2 input arrays are the same else throw
        require(
            _erc20AddressList.length == _mFactorList.length,
            "Inconsistent Inputs"
        );

        // Enter loop and token details
        for (uint256 i = 0; i < _erc20AddressList.length; i++) {
            addErc20(_erc20AddressList[i], _mFactorList[i]);
        }
        return true;
    }

    /**
     * @dev Removes a valid ERC20 addresses from the contract
     * @param _erc20Address - Address of the ERC20 contract to be removed
     * @return - Boolean status - True indicating successful completion
     * @notice - Access control: Only Owner
     */
    function removeErc20(address _erc20Address)
        public
        onlyOwner()
        returns (bool)
    {
        // Check if Valid ERC20 not equals MXX_ADDRESS
        require(_erc20Address != MXX_ADDRESS, "Cannot remove MXX");

        // Check if _erc20Address has existing yield contracts
        require(
            erc20Map[_erc20Address].noContracts == 0,
            "Token has existing contracts"
        );

        // Get array index and isFound flag
        uint256 index;
        bool isFound;
        (index, isFound) = getIndex(_erc20Address, erc20List);

        // Require address to be in list
        require(isFound, "Address not found");

        // Get last valid ERC20 address in the array
        address lastErc20Address = erc20List[erc20List.length - 1];

        // Assign last address to the index position
        erc20List[index] = lastErc20Address;

        // Delete last address from the array
        erc20List.pop();

        // Delete ERC20 details for the input address
        delete erc20Map[_erc20Address];
        return true;
    }

    /**
     * @dev Enlists/Delists ERC20 address to prevent adding new yield contracts with this ERC20 collateral
     * @param _erc20Address - Address of the ERC20 contract
     * @param _isValid - New validity boolean of the ERC20 contract
     * @return - Boolean status - True indicating successful completion
     * @notice - Access control: Only Owner
     */
    function setErc20Validity(address _erc20Address, bool _isValid)
        public
        onlyOwner()
        inErc20List(_erc20Address)
        returns (bool)
    {
        // Set valid ERC20 validity
        erc20Map[_erc20Address].isValid = _isValid;
        return true;
    }

    /**
     * @dev Updates the mint factor of a coin/token
     * @param _erc20Address - Address of the ERC20 contract or ETH address (ZERO_ADDRESS)
     * @return - Boolean status - True indicating successful completion
     * @notice - Access control: Only Owner
     */
    function updateMFactor(address _erc20Address, uint256 _mFactor)
        public
        onlyOwner()
        inErc20List(_erc20Address)
        onlyErc20OrEth(_erc20Address)
        returns (bool)
    {
        // Update mint factor
        erc20Map[_erc20Address].mFactor = _mFactor;
        return true;
    }

    /**
     * @dev Updates the mint factor for list of coin(s)/token(s)
     * @param _erc20AddressList - List of ERC20 addresses
     * @param _mFactorList - List of mint factors for ERC20 addresses
     * @return - Boolean status - True indicating successful completion
     * @notice - Length of the 2 input arrays must be the same
     * @notice - Access control: Only Owner
     */
    function updateMFactorList(
        address[] memory _erc20AddressList,
        uint256[] memory _mFactorList
    ) public onlyOwner() returns (bool) {
        // Length of the 2 input arrays must be the same. If condition fails, revert
        require(
            _erc20AddressList.length == _mFactorList.length,
            "Inconsistent Inputs"
        );

        // Enter the loop, update and return true
        for (uint256 i = 0; i < _erc20AddressList.length; i++) {
            updateMFactor(_erc20AddressList[i], _mFactorList[i]);
        }
        return true;
    }

    /**
     * @dev Returns number of valid Tokens/Coins supported
     * @return - Number of valid tokens/coins
     * @notice - Access control: Public
     */
    function getNoOfErc20s() public view returns (uint256) {
        return (erc20List.length);
    }

    /**
     * @dev Returns subset list of valid ERC20 contracts
     * @param _start - Start index to search in the list
     * @param _end - End index to search in the list
     * @return - List of valid ERC20 addresses subset
     * @notice - Access control: Public
     */
    function getSubsetErc20List(uint256 _start, uint256 _end)
        public
        view
        returns (address[] memory)
    {
        // If _end higher than length of array, set end index to last element of the array
        if (_end >= erc20List.length) {
            _end = erc20List.length - 1;
        }

        // Check conditions else fail
        require(_start <= _end, "Invalid limits");

        // Define return array
        uint256 noOfElements = _end - _start + 1;
        address[] memory subsetErc20List = new address[](noOfElements);

        // Loop in and add elements from erc20List array
        for (uint256 i = _start; i <= _end; i++) {
            subsetErc20List[i - _start] = erc20List[i];
        }
        return subsetErc20List;
    }

    /**
     * YIELD CONTRACT FUNCTIONS
     */

    /**
     * @dev Creates a yield contract
     * @param _erc20Address - The address of the ERC20 token (ZERO_ADDRESS if ETH)
     * @param _collateral - The collateral value of the ERC20 token or ETH
     * @param _tenure - The number of days of the agreement
     * @notice - Collateral to be input - Actual value * (10 power decimals)
     * @notice - For e.g If collateral is 5 USDT (Tether) and decimal is 6, then _collateral is (5 * (10 power 6))
     * Non Reentrant modifier is used to prevent re-entrancy attack
     * @notice - Access control: External
     */

    function createYieldContract(
        address _erc20Address,
        uint256 _collateral,
        uint16 _tenure
    ) external payable nonReentrant() {
        // Check if token/ETH is approved to create contracts
        require(erc20Map[_erc20Address].isValid, "Token/Coin not approved");

        // Create contractId and check if status Inactive (enum state 0)
        bytes32 contractId = keccak256(
            abi.encode(msg.sender, _erc20Address, now, allContracts.length)
        );
        require(
            contractMap[contractId].contractStatus == Status.Inactive,
            "Contract already exists"
        );

        // Check if APY (interest rate is not zero for the tenure)
        require(tenureApyMap[_tenure] != 0, "No interest rate is set");

        // Get decimal value for collaterals
        uint256 collateralDecimals;

        // Check id collateral is not 0
        require(_collateral != 0, "Collateral is 0");

        if (_erc20Address == ZERO_ADDRESS) {
            // In case of ETH, check to ensure if collateral value match ETH sent
            require(msg.value == _collateral, "Incorrect funds");

            // ETH decimals is 18
            collateralDecimals = 10**18;
        } else {
            // In case of non ETH, check to ensure if msg.value is 0
            require(msg.value == 0, "Incorrect funds");

            collateralDecimals = 10**uint256(ERC20(_erc20Address).decimals());

            // Transfer collateral
            ERC20(_erc20Address).safeTransferFrom(
                msg.sender,
                address(this),
                _collateral
            );
        }

        // Calculate MXX to be Minted
        uint256 numerator = _collateral
            .mul(erc20Map[_erc20Address].mFactor)
            .mul(tenureApyMap[_tenure])
            .mul(10**uint256(ERC20(MXX_ADDRESS).decimals()))
            .mul(_tenure);
        uint256 denominator = collateralDecimals
            .mul(erc20Map[MXX_ADDRESS].mFactor)
            .mul(365 * POW6);
        uint256 valueToBeMinted = numerator.div(denominator);

        // Update total MXX minted from yield contracts
        mxxMintedFromContract = mxxMintedFromContract.add(valueToBeMinted);

        // Check the MXX to be minted will result in total MXX allocated for creating yield contracts
        require(
            totalAllocatedMxx >= mxxMintedFromContract,
            "Total allocated MXX exceeded"
        );

        // Calculate MXX to be burnt
        numerator = valueToBeMinted.mul(contractFee);
        denominator = POW6;
        uint256 valueToBeBurnt = numerator.div(denominator);

        // Send valueToBeBurnt to contract fee destination
        ERC20(MXX_ADDRESS).safeTransferFrom(
            msg.sender,
            BURN_ADDRESS,
            valueToBeBurnt
        );

        // Create contract
        contractMap[contractId] = ContractDetails(
            msg.sender,
            uint48(now),
            uint48(now.add(uint256(_tenure).mul(1 days))),
            _erc20Address,
            _tenure,
            tenureApyMap[_tenure],
            Status.Active,
            _collateral,
            valueToBeMinted
        );

        // Push to all contracts and user contracts
        allContracts.push(contractId);

        // Increase number of contracts ERC20 details
        erc20Map[_erc20Address].noContracts += 1;
    }

    /**
     * @dev Early Redeem a yield contract
     * @param _contractId - The Id of the contract
     * Non Reentrant modifier is used to prevent re-entrancy attack
     * @notice - Access control: External
     */

    function earlyRedeemContract(bytes32 _contractId) external nonReentrant() {
        // Check if contract is Active
        require(
            contractMap[_contractId].contractStatus == Status.Active,
            "Contract is not active"
        );

        // Check if redeemer is the owner
        require(
            contractMap[_contractId].contractOwner == msg.sender,
            "Redeemer is not owner"
        );

        // Check if current time is less than end time
        require(
            now < contractMap[_contractId].endTime,
            "Contract is beyond its end time"
        );

        // Calculate mxxMintedTillDate
        uint256 numerator = now.sub(contractMap[_contractId].startTime).mul(
            contractMap[_contractId].mxxToBeMinted
        );
        uint256 denominator = uint256(contractMap[_contractId].endTime).sub(
            contractMap[_contractId].startTime
        );
        uint256 mxxMintedTillDate = numerator.div(denominator);

        // Calculate penaltyPercent
        numerator = uint256(maxEarlyRedeemFee).sub(minEarlyRedeemFee).mul(
            now.sub(contractMap[_contractId].startTime)
        );
        uint256 penaltyPercent = uint256(maxEarlyRedeemFee).sub(
            numerator.div(denominator)
        );

        // Calculate penaltyMXXToBurn
        numerator = penaltyPercent.mul(mxxMintedTillDate);
        uint256 penaltyMXXToBurn = numerator.div(POW6);

        // Check if penalty MXX to burn is not 0
        require(penaltyMXXToBurn != 0, "No penalty MXX");

        // Calculate mxxToBeSent
        uint256 mxxToBeSent = mxxMintedTillDate.sub(penaltyMXXToBurn);

        // Return collateral
        if (contractMap[_contractId].tokenAddress == ZERO_ADDRESS) {
            // Send back ETH
            (bool success, ) = contractMap[_contractId].contractOwner.call{
                value: contractMap[_contractId].collateral
            }("");
            require(success, "Transfer failed");
        } else {
            // Send back ERC20 collateral
            ERC20(contractMap[_contractId].tokenAddress).safeTransfer(
                contractMap[_contractId].contractOwner,
                contractMap[_contractId].collateral
            );
        }

        // Return MXX
        ERC20(MXX_ADDRESS).safeTransfer(
            contractMap[_contractId].contractOwner,
            mxxToBeSent
        );

        // Burn penalty fee
        ERC20(MXX_ADDRESS).safeTransfer(BURN_ADDRESS, penaltyMXXToBurn);

        // Updating contract
        contractMap[_contractId].startTime = uint48(now);
        contractMap[_contractId].mxxToBeMinted = contractMap[_contractId]
            .mxxToBeMinted
            .sub(mxxMintedTillDate);
        contractMap[_contractId].contractOwner = ZERO_ADDRESS;
        contractMap[_contractId].contractStatus = Status.OpenMarket;
    }

    /**
     * @dev Acquire a yield contract in the open market
     * @param _contractId - The Id of the contract
     * Non Reentrant modifier is used to prevent re-entrancy attack
     * @notice - Access control: External
     */

    function acquireYieldContract(bytes32 _contractId)
        external
        payable
        nonReentrant()
    {
        // Check if contract is open
        require(
            contractMap[_contractId].contractStatus == Status.OpenMarket,
            "Contract not in open market"
        );

        // Get collateral in case of ERC20 tokens, for ETH it is already received via msg.value
        if (contractMap[_contractId].tokenAddress != ZERO_ADDRESS) {
            // In case of ERC20, ensure no ETH is sent
            require(msg.value == 0, "ETH should not be sent");
            ERC20(contractMap[_contractId].tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                contractMap[_contractId].collateral
            );
        } else {
            // In case of ETH check if money received equals the collateral else revert
            require(
                msg.value == contractMap[_contractId].collateral,
                "Incorrect funds"
            );
        }

        // Updating contract
        contractMap[_contractId].contractOwner = msg.sender;
        contractMap[_contractId].contractStatus = Status.Active;
    }

    /**
     * @dev Destroy an open market yield contract
     * @param _contractId - The Id of the contract
     * Non Reentrant modifier is used to prevent re-entrancy attack
     * @notice - Access control: External
     */

    function destroyOMContract(bytes32 _contractId)
        external
        onlyOwner()
        nonReentrant()
    {
        // Check if contract is open
        require(
            contractMap[_contractId].contractStatus == Status.OpenMarket,
            "Contract not in open market"
        );

        // Reduced MXX minted from contract and update status as destroyed
        mxxMintedFromContract -= contractMap[_contractId].mxxToBeMinted;
        contractMap[_contractId].contractStatus = Status.Destroyed;
    }

    /**
     * @dev Claim a yield contract in the active market
     * @param _contractId - The Id of the contract
     * Non Reentrant modifier is used to prevent re-entrancy attack
     * @notice - Access control: External
     */

    function claimYieldContract(bytes32 _contractId) external nonReentrant() {
        // Check if contract is active
        require(
            contractMap[_contractId].contractStatus == Status.Active,
            "Contract is not active"
        );

        // Check if owner and msg.sender are the same
        require(
            contractMap[_contractId].contractOwner == msg.sender,
            "Contract owned by someone else"
        );

        // Check if current time is greater than contract end time
        require(now >= contractMap[_contractId].endTime, "Too early to claim");

        // Return collateral
        if (contractMap[_contractId].tokenAddress == ZERO_ADDRESS) {
            // Send back ETH
            (bool success, ) = contractMap[_contractId].contractOwner.call{
                value: contractMap[_contractId].collateral
            }("");
            require(success, "Transfer failed");
        } else {
            // Send back ERC20 collateral
            ERC20(contractMap[_contractId].tokenAddress).safeTransfer(
                contractMap[_contractId].contractOwner,
                contractMap[_contractId].collateral
            );
        }

        // Return minted MXX
        ERC20(MXX_ADDRESS).safeTransfer(
            contractMap[_contractId].contractOwner,
            contractMap[_contractId].mxxToBeMinted
        );

        // Updating contract
        contractMap[_contractId].contractStatus = Status.Claimed;

        // Reduce no of contracts in ERC20 details
        erc20Map[contractMap[_contractId].tokenAddress].noContracts -= 1;
    }

    /**
     * @dev This function will subset of yield contract
     * @param _start - Start of the list
     * @param _end - End of the list
     * @return - List of subset yield contract
     * Access Control: Public
     */

    function getSubsetYieldContracts(uint256 _start, uint256 _end)
        public
        view
        returns (bytes32[] memory)
    {
        // If _end higher than length of array, set end index to last element of the array
        if (_end >= allContracts.length) {
            _end = allContracts.length.sub(1);
        }

        // Check conditions else fail
        require(_start <= _end, "Invalid limits");

        // Define return array
        uint256 noOfElements = _end.sub(_start).add(1);
        bytes32[] memory subsetYieldContracts = new bytes32[](noOfElements);

        // Loop in and add elements from allContracts array
        for (uint256 i = _start; i <= _end; i++) {
            subsetYieldContracts[i - _start] = allContracts[i];
        }

        return subsetYieldContracts;
    }

    /**
     * @dev This function will withdraw MXX back to the owner
     * @param _amount - Amount of MXX need to withdraw
     * @return - Boolean status indicating successful completion
     * Access Control: Only Owner
     */

    function withdrawMXX(uint256 _amount)
        public
        onlyOwner()
        nonReentrant()
        returns (bool)
    {
        ERC20(MXX_ADDRESS).safeTransfer(msg.sender, _amount);
        return true;
    }
}
