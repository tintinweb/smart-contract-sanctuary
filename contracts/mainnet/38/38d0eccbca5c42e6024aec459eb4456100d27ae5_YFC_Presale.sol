pragma solidity ^0.5.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
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

    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    function mint(address account, uint256 amount) public returns (bool);

    function burn(uint256 amount) public returns (bool);
}


contract YFC_Presale is Ownable {
    address private yfcCoinddress;
    uint256 private price;
    address private messenger;

    using SafeMath for uint256;

    constructor(address _yfcCoinddress, uint256 _initialPrice) public {
        yfcCoinddress = _yfcCoinddress;
        price = _initialPrice;
    }

    event bought(address _buyer, uint256 _paid, uint256 _given);
    event priceChanged(address initiator, uint256 _from, uint256 _to);
    event messengerChanged(address _from, address _to);
    modifier onlyMessenger() {
        require(msg.sender == messenger, "caller is not a messenger");
        _;
    }

    function updatePrice(uint256 _price) public onlyMessenger {
        uint256 currentprice = price;
        price = _price;
        emit priceChanged(msg.sender, currentprice, _price);
    }

    function setMessenger(address _messenger) public onlyOwner {
        address currentMessenger = messenger;
        messenger = _messenger;
        emit messengerChanged(currentMessenger, _messenger);
    }

    function setYFCCoin(address _yfcCoinddress) public onlyOwner {
        yfcCoinddress = _yfcCoinddress;
    }

    function getPrice() public view returns (uint256 _price) {
        return price;
    }

    function buyer() public payable {
        require(msg.value > 0, "Invalid amount");
        uint256 amount = msg.value; //.mul(10**18);
        IERC20 YFCCoin = IERC20(yfcCoinddress);
        uint256 amountToSend = amount.div(price).mul(10**18);
        require(
            YFCCoin.transfer(msg.sender, amountToSend),
            "Fail to send fund"
        );
        emit bought(msg.sender, msg.value, amountToSend);
    }

    function withdrawAllEtherByOwner() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }
}