// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

pragma solidity ^0.6.0;
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

pragma solidity 0.6.12;
interface IERC1155NFT {
    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external ;
	function totalSupply(uint256 _id) external view returns (uint256);
    function maxSupply(uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
}

pragma solidity 0.6.12;
interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

pragma solidity 0.6.12;
contract Utils {
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

pragma solidity 0.6.12;
contract ERC20Token is IERC20Token, Utils {
    using SafeMath for uint256;


    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint256 public override totalSupply;
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) public {
        require(bytes(_name).length > 0, "ERR_INVALID_NAME");
        require(bytes(_symbol).length > 0, "ERR_INVALID_SYMBOL");

        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_to)
        returns (bool)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_from)
        validAddress(_to)
        returns (bool)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        validAddress(_spender)
        returns (bool)
    {
        require(_value == 0 || allowance[msg.sender][_spender] == 0, "ERR_INVALID_AMOUNT");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

pragma solidity 0.6.12;
interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

pragma solidity 0.6.12;
interface ITokenHolder is IOwnable {
    function mintTo(IERC20Token _token, address _to, uint256 _amount) external;
    function mintFrom(IERC20Token _token, address _from, address _to, uint256 _amount) external;
}

pragma solidity 0.6.12;
interface IConverterAnchor is IOwnable, ITokenHolder {
}

pragma solidity 0.6.12;
interface IERCToken is IConverterAnchor, IERC20Token {
    function disableTransfers(bool _disable) external;
    function issue(address _to, uint256 _amount) external;
    function destroy(address _from, uint256 _amount) external;
}

pragma solidity 0.6.12;
contract Ownable is IOwnable {
    address public override owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnerUpdate(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

pragma solidity 0.6.12;
contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_APPROVE_FAILED');
    }

    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FAILED');
    }

    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FROM_FAILED');
    }
}

pragma solidity 0.6.12;
contract TokenHolder is ITokenHolder, TokenHandler, Ownable, Utils {
    function mintTo(IERC20Token _token, address _to, uint256 _amount)
        public
        virtual
        override
        onlyOwner
        validAddress(address(_token))
        validAddress(_to)
    {
        safeTransfer(_token, _to, _amount);
    }

    function mintFrom(IERC20Token _token, address _from, address _to, uint256 _amount)
        public
        virtual
        override
        onlyOwner
        validAddress(address(_token))
        validAddress(_from)
        validAddress(_to)
    {
        safeTransferFrom(_token, _from, _to, _amount);
    }
}

pragma solidity 0.6.12;
contract ERCToken is IERCToken, Ownable, ERC20Token, TokenHolder {
    using SafeMath for uint256;

    bool public transfersEnabled = true;
    event Issuance(uint256 _amount);
    event Destruction(uint256 _amount);
    constructor(string memory _name, string memory _symbol)
        public
        ERC20Token(_name, _symbol, 0)
    {
    }

    modifier transfersAllowed {
        _transfersAllowed();
        _;
    }

    function setTokenName(string memory _newTokenName) public onlyOwner {
        name = _newTokenName;
    }

    function setTokenSymbol(string memory _newTokenSymbol) public onlyOwner {
        symbol = _newTokenSymbol;
    }

    function setDecimals(uint8 _newDecimals) public onlyOwner {
        decimals = _newDecimals;
    }
    
    function setTotalSupply(uint256 _newTotalSupply) public onlyOwner {
        totalSupply = _newTotalSupply;
    }

    function _transfersAllowed() internal view {
        require(transfersEnabled, "ERR_TRANSFERS_DISABLED");
    }

    function disableTransfers(bool _disable) public override onlyOwner {
        transfersEnabled = !_disable;
    }

    function issue(address _to, uint256 _amount)
        public
        override
        onlyOwner
        validAddress(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function destroy(address _from, uint256 _amount) public override onlyOwner {
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }

    function transfer(address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        transfersAllowed
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        transfersAllowed
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }
}

pragma solidity 0.6.12;
interface IMigratorErcs {
    function migrate(IERC20 token) external returns (IERC20);
}
library UniformRandomNumber {
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UniformRand/min-bound");
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

contract ERC20Contract is ERCToken("ERC20 Token", "ERC20") {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address[] public airdropList;
    mapping(address => bool) addressAvailable;
    mapping(address => bool) addressAvailableHistory;
    struct UserNftInfo {
        uint256 amount;
    }
    mapping (address => mapping (uint256 => UserNftInfo)) public userNftInfo;
    struct NftInfo {
        uint256 nftID;
        uint256 amount;
        uint256 fixedPrice;
    }
    NftInfo[] public nftInfo;
    uint256 public totalNftAmount = 0;
    uint256 public originalTotalNftAmount = 0;
    uint256 public ercsRequired = 1000 * (10 ** 18);
    uint256 public base = 10 ** 6;
    uint256 public totalFee = 3 * (base) / 100;

    IERC1155NFT ERC1155NFT;

    event Reward(address indexed user, uint256 indexed nftID);
    event AirDrop(address indexed user, uint256 indexed nftID);

    function nftLength() public view returns (uint256) {
        return nftInfo.length;
    }

    function ercBalanceOf(address tokenOwner) public view returns (uint256) {
        return balanceOf[tokenOwner];
    }

    function userNftBalanceOf(address tokenOwner, uint256 _nftID) public view returns (uint256) {
        return userNftInfo[tokenOwner][_nftID].amount;
    }

    function userUnclaimNft(address tokenOwner) public view returns (uint256[] memory) {
        uint256[] memory userNft = new uint256[](nftInfo.length);
        for(uint i = 0; i < nftInfo.length; i++) {
            userNft[i] = userNftInfo[tokenOwner][i].amount;
        }
        return userNft;
    }

    function nftBalanceOf(uint256 _nftID) public view returns (uint256) {
        return nftInfo[_nftID].amount;
    }

    function setErcsRequired(uint256 _newErcsRequired) public onlyOwner {
        ercsRequired = _newErcsRequired;
    }

    function setTotalFee(uint256 _newTotalFee) public onlyOwner {
        totalFee = _newTotalFee;
    }

    function addNft(uint256 _nftID, uint256 _amount, uint256 _fixedPrice) external onlyOwner {
        require(_amount.add(ERC1155NFT.totalSupply(_nftID)) <= ERC1155NFT.maxSupply(_nftID), "Max supply reached");
        totalNftAmount = totalNftAmount.add(_amount);
        originalTotalNftAmount = originalTotalNftAmount.add(_amount);
        nftInfo.push(NftInfo({
            nftID: _nftID,
            amount: _amount,
            fixedPrice: _fixedPrice
        }));
    }

    function _updateNft(uint256 _wid, uint256 amount) internal {
        NftInfo storage nft = nftInfo[_wid];
        nft.amount = nft.amount.sub(amount);
        totalNftAmount = totalNftAmount.sub(amount);
    }

    function _addUserNft(address user, uint256 _wid, uint256 amount) internal {
        UserNftInfo storage userNft = userNftInfo[user][_wid];
        userNft.amount = userNft.amount.add(amount);
    }
    function _removeUserNft(address user, uint256 _wid, uint256 amount) internal {
        UserNftInfo storage userNft = userNftInfo[user][_wid];
        userNft.amount = userNft.amount.sub(amount);
    }

    function _draw() internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
        uint256 rnd = UniformRandomNumber.uniform(seed, totalNftAmount);
        for(uint i = nftInfo.length - 1; i > 0; --i){
            if(rnd < nftInfo[i].amount){
                return i;
            }
            rnd = rnd - nftInfo[i].amount;
        }
        return uint256(-1);
    }

    function draw() external {
        require(msg.sender == tx.origin);

        require(balanceOf[msg.sender] >= ercsRequired, "Ercs are not enough.");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(ercsRequired);

        uint256 _rwid = _draw();
        _updateNft(_rwid, 1);
        _addUserNft(msg.sender, _rwid, 1);

        emit Reward(msg.sender, _rwid);
    }

    function airDrop() external onlyOwner {

        uint256 _rwid = _draw();
        _updateNft(_rwid, 1);

        uint256 seed = uint256(keccak256(abi.encodePacked(now, _rwid)));
        bool status = false;
        uint256 rnd = 0;

        while (!status) {
            rnd = UniformRandomNumber.uniform(seed, airdropList.length);
            status = addressAvailable[airdropList[rnd]];
            seed = uint256(keccak256(abi.encodePacked(seed, rnd)));
        }

        _addUserNft(airdropList[rnd], _rwid, 1);
        emit AirDrop(airdropList[rnd], _rwid);
    }

    function airDropByUser() external {

        require(msg.sender == tx.origin);

        require(balanceOf[msg.sender] >= ercsRequired, "Ercs are not enough.");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(ercsRequired);
        
        uint256 _rwid = _draw();
        _updateNft(_rwid, 1);

        uint256 seed = uint256(keccak256(abi.encodePacked(now, _rwid)));
        bool status = false;
        uint256 rnd = 0;

        while (!status) {
            rnd = UniformRandomNumber.uniform(seed, airdropList.length);
            status = addressAvailable[airdropList[rnd]];
            seed = uint256(keccak256(abi.encodePacked(seed, rnd)));
        }

        _addUserNft(airdropList[rnd], _rwid, 1);
        emit AirDrop(airdropList[rnd], _rwid);
    }

    function withdrawFee() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function claimFee(uint256 _wid, uint256 amount) public view returns (uint256){
        NftInfo storage nft = nftInfo[_wid];
        return amount * nft.fixedPrice * (totalFee) / (base);
    }

    function claim(uint256 _wid, uint256 amount) external payable {
        UserNftInfo storage userNft = userNftInfo[msg.sender][_wid];
        require(amount > 0, "amount must not zero");
        require(userNft.amount >= amount, "amount is bad");
        require(msg.value == claimFee(_wid, amount), "need payout claim fee");

        _removeUserNft(msg.sender, _wid, amount);
        ERC1155NFT.mint(msg.sender, _wid, amount, "");
    }
}


contract SmartContract is ERC20Contract {
    struct UserLPInfo {
        uint256 amount;
        uint256 rewardERC;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accERCPerShare;
    }
    address public devaddr;
    uint256 public bonusEndBlock;
    uint256 public ercPerBlock = 1000000000000000000;
    uint256 public bonusMultiplier = 2;
    IMigratorErcs public migrator;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserLPInfo)) public userLPInfo;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC1155NFT _ERC1155NFT,
        address _devaddr,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        ERC1155NFT = _ERC1155NFT;
        devaddr = _devaddr;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        nftInfo.push(NftInfo({
            nftID: 0,
            amount: 0,
            fixedPrice: 0
        }));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function NFT() external view returns (IERC1155NFT) {
        return ERC1155NFT;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accERCPerShare: 0
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setERC1155NFT(IERC1155NFT _newERC1155NFT) public onlyOwner {
        ERC1155NFT = _newERC1155NFT;
    }

    function setERCPerBlock(uint256 _ercPerBlock) public onlyOwner {
        ercPerBlock = _ercPerBlock;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }

    function setBonusMultiplier(uint256 _bonusMultiplier) public onlyOwner {
        bonusMultiplier = _bonusMultiplier;
    }

    function setNewLpToken(uint _pid, IERC20 _newLpToken) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.lpToken = _newLpToken;
    }

    function setNewAllocPoint(uint _pid, uint256 _newAllocPoint) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.allocPoint = _newAllocPoint;
    }

    function setMigrator(IMigratorErcs _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function migrate(uint256 _pid) public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        pool.lpToken = newLpToken;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(bonusMultiplier).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    function pendingERC(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_user];
        uint256 accERCPerShare = pool.accERCPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ercReward = multiplier.mul(ercPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accERCPerShare = accERCPerShare.add(ercReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accERCPerShare).div(1e12).sub(user.rewardERC);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ercReward = multiplier.mul(ercPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        issue(devaddr, ercReward.mul(10).div(100));
        issue(address(this), ercReward.mul(90).div(100));
        pool.accERCPerShare = pool.accERCPerShare.add(ercReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        require(msg.sender == tx.origin);

        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accERCPerShare).div(1e12).sub(user.rewardERC);
            if(pending > 0) {
                safeErcTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardERC = user.amount.mul(pool.accERCPerShare).div(1e12);
        if (user.amount > 0){
            addressAvailable[msg.sender] = true;
            if(!addressAvailableHistory[msg.sender]){
                addressAvailableHistory[msg.sender] = true;
                airdropList.push(msg.sender);
            }
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accERCPerShare).div(1e12).sub(user.rewardERC);
        if(pending > 0) {
            safeErcTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardERC = user.amount.mul(pool.accERCPerShare).div(1e12);
        if (user.amount == 0){
            addressAvailable[msg.sender] = false;
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardERC = 0;
        addressAvailable[msg.sender] = false;
    }

    function safeErcTransfer(address _to, uint256 _amount) internal {
        uint256 ercBal = ercBalanceOf(address(this));
        if (_amount > ercBal) {
            transfer(_to, ercBal);
        } else {
            transfer(_to, _amount);
        }
    }

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}