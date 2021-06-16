/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// contracts/multisender.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.5.7;


/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

pragma solidity 0.5.7;


/**
 * @title UpgradeabilityStorage
 * @dev This contract holds all the necessary state variables to support the upgrade functionality
 */
contract UpgradeabilityStorage {
    // Version name of the current implementation
    string internal _version;

    // Address of the current implementation
    address internal _implementation;

    /**
    * @dev Tells the version name of the current implementation
    * @return string representing the name of the current version
    */
    function version() public view returns (string memory) {
        return _version;
    }

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }
}

pragma solidity 0.5.7;


/**
 * @title UpgradeabilityOwnerStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract UpgradeabilityOwnerStorage {
    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
    * @dev Sets the address of the owner
    */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

pragma solidity 0.5.7;





/**
 * @title OwnedUpgradeabilityStorage
 * @dev This is the storage necessary to perform upgradeable contracts.
 * This means, required state variables for upgradeability purpose and eternal storage per se.
 */
contract OwnedUpgradeabilityStorage is UpgradeabilityOwnerStorage, UpgradeabilityStorage, EternalStorage {}

pragma solidity 0.5.7;



/**
 * @title Ownable
 * @dev This contract has an owner address providing basic authorization control
 */
contract Ownable is EternalStorage {
    /**
    * @dev Event to show ownership has been transferred
    * @param previousOwner representing the address of the previous owner
    * @param newOwner representing the address of the new owner
    */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner(), "not an owner");
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return addressStorage[keccak256("owner")];
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256("owner")] = newOwner;
    }
}

pragma solidity 0.5.7;




/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is EternalStorage, Ownable {
    function pendingOwner() public view returns (address) {
        return addressStorage[keccak256("pendingOwner")];
    }

    /**
    * @dev Modifier throws if called by any account other than the pendingOwner.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner());
        _;
    }

    /**
    * @dev Allows the current owner to set the pendingOwner address.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        addressStorage[keccak256("pendingOwner")] = newOwner;
    }

    /**
    * @dev Allows the pendingOwner address to finalize the transfer.
    */
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner(), pendingOwner());
        addressStorage[keccak256("owner")] = addressStorage[keccak256("pendingOwner")];
        addressStorage[keccak256("pendingOwner")] = address(0);
    }
}


pragma solidity 0.5.7;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity 0.5.7;


contract Messages is EternalStorage {
    struct Authorization {
        address authorizedSigner;
        uint256 expiration;
    }
    /**
     * Domain separator encoding per EIP 712.
     * keccak256(
     *     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
     * )
     */
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    /**
     * Validator struct type encoding per EIP 712
     * keccak256(
     *     "Authorization(address authorizedSigner,uint256 expiration)"
     * )
     */
    bytes32 private constant AUTHORIZATION_TYPEHASH = 0xe419504a688f0e6ea59c2708f49b2bbc10a2da71770bd6e1b324e39c73e7dc25;


    /**
     * Domain separator per EIP 712
     */
    // bytes32 public DOMAIN_SEPARATOR;
    function DOMAIN_SEPARATOR() public view returns(bytes32) {
        bytes32 salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
        return keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Multisender"),
                keccak256("2.0"),
                uintStorage[keccak256("chainId")],
                address(this),
                salt
            ));
    }

    /**
     * @notice Calculates authorizationHash according to EIP 712.
     * @param _authorizedSigner address of trustee
     * @param _expiration expiration date
     * @return bytes32 EIP 712 hash of _authorization.
     */
    function hash(address _authorizedSigner, uint256 _expiration) public pure returns (bytes32) {
        return keccak256(abi.encode(
                AUTHORIZATION_TYPEHASH,
                _authorizedSigner,
                _expiration
            ));
    }

    /**
     * @return the recovered address from the signature
     */
    function recoverAddress(
        bytes32 messageHash,
        bytes memory signature
    )
    public
    view
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        bytes1 v;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                messageHash
            ));
        return ecrecover(digest, uint8(v), r, s);
    }

    function getApprover(uint256 timestamp, bytes memory signature) public view returns(address) {
        if (timestamp < now) {
            return address(0);
        }
        bytes32 messageHash = hash(msg.sender, timestamp);
        return recoverAddress(messageHash, signature);
    }


}

pragma solidity 0.5.7;






/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public
    view
    returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract UpgradebleStormSender is
OwnedUpgradeabilityStorage,
Claimable,
Messages
{
    using SafeMath for uint256;

    event Multisended(uint256 total, address tokenAddress);
    event ClaimedTokens(address token, address owner, uint256 balance);
    event PurchaseVIP(address customer, uint256 tier);

    modifier hasFee() {
        uint256 contractFee = currentFee(msg.sender);
        if (contractFee > 0) {
            require(msg.value >= contractFee, "no fee");
        }
        _;
    }

    modifier validLists(uint256 _contributorsLength, uint256 _balancesLength) {
        require(_contributorsLength > 0, "no contributors sent");
        require(
            _contributorsLength == _balancesLength,
            "different arrays lengths"
        );
        _;
    }

    function() external payable {}

    function initialize(
        address _owner,
        uint256 _fee,
        uint256 _vipPrice0,
        uint256 _vipPrice1,
        uint256 _vipPrice2,
        uint256 _chainId
    ) public {
        require(!initialized() || msg.sender == owner());
        setOwner(_owner);
        setFee(_fee); // 0.05 ether fee
        setVipPrice(0, _vipPrice0); // 1 eth
        setVipPrice(1, _vipPrice1); // 5 eth
        setVipPrice(2, _vipPrice2); // 10 eth
        uintStorage[keccak256("chainId")] = _chainId;
        boolStorage[keccak256("rs_multisender_initialized")] = true;
        require(fee() >= 0.01 ether);
        uintStorage[keccak256("referralFee")] = 0.01 ether;
    }

    function initialized() public view returns (bool) {
        return boolStorage[keccak256("rs_multisender_initialized")];
    }

    function fee() public view returns (uint256) {
        return uintStorage[keccak256("fee")];
    }

    function currentFee(address _customer) public view returns (uint256) {
        if (getUnlimAccess(_customer) >= block.timestamp) {
            return 0;
        }
        return fee();
    }

    function setFee(uint256 _newStep) public onlyOwner {
        require(_newStep != 0);
        uintStorage[keccak256("fee")] = _newStep;
    }

    function tokenFallback(address _from, uint256 _value, bytes memory _data)
    public
    {}

    function _checkFee(address _user, address payable _referral) internal {
        uint256 contractFee = currentFee(_user);
        if (contractFee > 0) {
            require(msg.value >= contractFee, "no fee");
            if (_referral != address(0)) {
                _referral.send(referralFee());
            }
        }
    }

    function multisendToken(
        address _token,
        address[] calldata _contributors,
        uint256[] calldata _balances,
        uint256 _total,
        address payable _referral
    ) external payable validLists(_contributors.length, _balances.length) {
        bool isGoodToken;
        bytes memory data;
        _checkFee(msg.sender, _referral);
        uint256 change = 0;
        ERC20 erc20token = ERC20(_token);
        // bytes4 transferFrom = 0x23b872dd;
        (isGoodToken, data) = _token.call(
            abi.encodeWithSelector(
                0x23b872dd,
                msg.sender,
                address(this),
                _total
            )
        );
        require(isGoodToken, "transferFrom failed");
        if (data.length > 0) {
            bool success = abi.decode(data, (bool));
            require(success, "not enough allowed tokens");
        }
        for (uint256 i = 0; i < _contributors.length; i++) {
            (bool success, ) = _token.call(
                abi.encodeWithSelector(
                    erc20token.transfer.selector,
                    _contributors[i],
                    _balances[i]
                )
            );
            if (!success) {
                change += _balances[i];
            }
        }
        if (change != 0) {
            erc20token.transfer(msg.sender, change);
        }
        emit Multisended(_total, _token);
    }

    function findBadAddressesForBurners(
        address _token,
        address[] calldata _contributors,
        uint256[] calldata _balances,
        uint256 _total
    )
    external
    payable
    validLists(_contributors.length, _balances.length)
    hasFee
    returns (address[] memory badAddresses, uint256[] memory badBalances)
    {
        badAddresses = new address[](_contributors.length);
        badBalances = new uint256[](_contributors.length);
        ERC20 erc20token = ERC20(_token);
        for (uint256 i = 0; i < _contributors.length; i++) {
            (bool success, ) = _token.call(
                abi.encodeWithSelector(
                    erc20token.transferFrom.selector,
                    msg.sender,
                    _contributors[i],
                    _balances[i]
                )
            );
            if (!success) {
                badAddresses[i] = _contributors[i];
                badBalances[i] = _balances[i];
            }
        }
    }

    function multisendTokenForBurners(
        address _token,
        address[] calldata _contributors,
        uint256[] calldata _balances,
        uint256 _total,
        address payable _referral
    ) external payable validLists(_contributors.length, _balances.length) {
        _checkFee(msg.sender, _referral);
        ERC20 erc20token = ERC20(_token);
        for (uint256 i = 0; i < _contributors.length; i++) {
            (bool success, ) = _token.call(
                abi.encodeWithSelector(
                    erc20token.transferFrom.selector,
                    msg.sender,
                    _contributors[i],
                    _balances[i]
                )
            );
        }
        emit Multisended(_total, _token);
    }

    function multisendTokenForBurnersWithSignature(
        address _token,
        address[] calldata _contributors,
        uint256[] calldata _balances,
        uint256 _total,
        address payable _referral,
        bytes calldata _signature,
        uint256 _timestamp
    ) external payable {
        address tokenHolder = getApprover(_timestamp, _signature);
        require(
            tokenHolder != address(0),
            "the signature is invalid or has expired"
        );
        require(_contributors.length > 0, "no contributors sent");
        require(
            _contributors.length == _balances.length,
            "different arrays lengths"
        );
        // require(msg.value >= currentFee(tokenHolder), "no fee");
        _checkFee(tokenHolder, _referral);
        ERC20 erc20token = ERC20(_token);
        for (uint256 i = 0; i < _contributors.length; i++) {
            (bool success, ) = _token.call(
                abi.encodeWithSelector(
                    erc20token.transferFrom.selector,
                    tokenHolder,
                    _contributors[i],
                    _balances[i]
                )
            );
        }
        emit Multisended(_total, _token);
    }

    function multisendTokenWithSignature(
        address _token,
        address[] calldata _contributors,
        uint256[] calldata _balances,
        uint256 _total,
        address payable _referral,
        bytes calldata _signature,
        uint256 _timestamp
    ) external payable {
        bool isGoodToken;
        address tokenHolder = getApprover(_timestamp, _signature);
        require(
            tokenHolder != address(0),
            "the signature is invalid or has expired"
        );
        require(_contributors.length > 0, "no contributors sent");
        require(
            _contributors.length == _balances.length,
            "different arrays lengths"
        );
        _checkFee(tokenHolder, _referral);
        uint256 change = 0;
        (isGoodToken, ) = _token.call(
            abi.encodeWithSelector(
                0x23b872dd,
                tokenHolder,
                address(this),
                _total
            )
        );
        require(isGoodToken, "not enough allowed tokens");
        for (uint256 i = 0; i < _contributors.length; i++) {
            (bool success, ) = _token.call(
                abi.encodeWithSelector(
                // transfer
                    0xa9059cbb,
                    _contributors[i],
                    _balances[i]
                )
            );
            if (!success) {
                change += _balances[i];
            }
        }
        if (change != 0) {
            _token.call(
                abi.encodeWithSelector(
                // transfer
                    0xa9059cbb,
                    tokenHolder,
                    change
                )
            );
        }
        emit Multisended(_total, _token);
    }

    // DONT USE THIS METHOD, only for eth_call
    function tokenFindBadAddresses(
        address _token,
        address[] calldata _contributors,
        uint256[] calldata _balances,
        uint256 _total
    )
    external
    payable
    validLists(_contributors.length, _balances.length)
    hasFee
    returns (address[] memory badAddresses, uint256[] memory badBalances)
    {
        badAddresses = new address[](_contributors.length);
        badBalances = new uint256[](_contributors.length);
        ERC20 erc20token = ERC20(_token);
        bool isGoodToken;
        (isGoodToken, ) = _token.call(
            abi.encodeWithSelector(
                0x23b872dd,
                msg.sender,
                address(this),
                _total
            )
        );
        // erc20token.transferFrom(msg.sender, address(this), _total);
        for (uint256 i = 0; i < _contributors.length; i++) {
            (bool success, ) = _token.call(
                abi.encodeWithSelector(
                    erc20token.transfer.selector,
                    _contributors[i],
                    _balances[i]
                )
            );
            if (!success) {
                badAddresses[i] = _contributors[i];
                badBalances[i] = _balances[i];
            }
        }
    }

    // DONT USE THIS METHOD, only for eth_call
    function etherFindBadAddresses(
        address payable[] calldata _contributors,
        uint256[] calldata _balances
    )
    external
    payable
    validLists(_contributors.length, _balances.length)
    returns (address[] memory badAddresses, uint256[] memory badBalances)
    {
        badAddresses = new address[](_contributors.length);
        badBalances = new uint256[](_contributors.length);

        uint256 _total = msg.value;
        uint256 _contractFee = currentFee(msg.sender);
        _total = _total.sub(_contractFee);

        for (uint256 i = 0; i < _contributors.length; i++) {
            bool _success = _contributors[i].send(_balances[i]);
            if (!_success) {
                badAddresses[i] = _contributors[i];
                badBalances[i] = _balances[i];
            } else {
                _total = _total.sub(_balances[i]);
            }
        }
    }

    function multisendEther(
        address payable[] calldata _contributors,
        uint256[] calldata _balances
    ) external payable validLists(_contributors.length, _balances.length) {
        uint256 _contractBalanceBefore = address(this).balance.sub(msg.value);
        uint256 _total = msg.value;
        uint256 _contractFee = currentFee(msg.sender);
        _total = _total.sub(_contractFee);

        for (uint256 i = 0; i < _contributors.length; i++) {
            bool _success = _contributors[i].send(_balances[i]);
            if (_success) {
                _total = _total.sub(_balances[i]);
            }
        }

        uint256 _contractBalanceAfter = address(this).balance;
        // assert. Just for sure
        require(
            _contractBalanceAfter >= _contractBalanceBefore.add(_contractFee),
            "don’t try to take the contract money"
        );

        emit Multisended(_total, 0x000000000000000000000000000000000000bEEF);
    }

    function setVipPrice(uint256 _tier, uint256 _price) public onlyOwner {
        uintStorage[keccak256(abi.encodePacked("vip", _tier))] = _price;
    }

    function setAddressToVip(address _address, uint256 _tier)
    external
    onlyOwner
    {
        setUnlimAccess(_address, _tier);
        emit PurchaseVIP(msg.sender, _tier);
    }

    function buyVip(uint256 _tier) external payable {
        require(
            msg.value >= uintStorage[keccak256(abi.encodePacked("vip", _tier))]
        );
        setUnlimAccess(msg.sender, _tier);
        emit PurchaseVIP(msg.sender, _tier);
    }

    function setReferralFee(uint256 _newFee) external onlyOwner {
        require(fee() >= _newFee);
        uintStorage[keccak256("referralFee")] = _newFee;
    }

    function referralFee() public view returns (uint256) {
        return uintStorage[keccak256("referralFee")];
    }

    function getVipPrice(uint256 _tier) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("vip", _tier))];
    }

    function getAllVipPrices()
    external
    view
    returns (uint256 tier0, uint256 tier1, uint256 tier2)
    {
        return (
        uintStorage[keccak256(abi.encodePacked("vip", uint256(0)))],
        uintStorage[keccak256(abi.encodePacked("vip", uint256(1)))],
        uintStorage[keccak256(abi.encodePacked("vip", uint256(2)))]
        );
    }

    function claimTokens(address _token, uint256 _amount) external onlyOwner {
        address payable ownerPayable = address(uint160(owner()));
        uint256 amount = _amount;
        if (_amount == 0) {
            amount = address(this).balance;
        }
        if (_token == address(0)) {
            ownerPayable.transfer(amount);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        amount = erc20token.balanceOf(address(this));
        erc20token.transfer(ownerPayable, amount);
        emit ClaimedTokens(_token, ownerPayable, amount);
    }

    function getDeadline(uint256 _tier) public view returns (uint256) {
        // 1 day
        if (_tier == 0) {
            return block.timestamp + 1 days;
        }
        // 7 days
        if (_tier == 1) {
            return block.timestamp + 7 days;
        }
        // Lifetime
        if (_tier == 2) {
            return block.timestamp + 30 days;
        }
        return 0;
    }

    function getUnlimAccess(address customer) public view returns (uint256) {
        return
        uintStorage[keccak256(abi.encodePacked("unlimAccess", customer))];
    }

    function setUnlimAccess(address customer, uint256 _tier) private {
        uintStorage[keccak256(
            abi.encodePacked("unlimAccess", customer)
        )] = getDeadline(_tier);
    }

    function exploreETHBalances(address[] calldata targets)
    external
    view
    returns (uint256[] memory balances)
    {
        balances = new uint256[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            balances[i] = targets[i].balance;
        }
    }

    function exploreERC20Balances(ERC20 token, address[] calldata targets)
    external
    view
    returns (uint256[] memory balances)
    {
        balances = new uint256[](targets.length);
        for (uint256 i = 0; i < targets.length; i++) {
            balances[i] = token.balanceOf(targets[i]);
        }
    }
}