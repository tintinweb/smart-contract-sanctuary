/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DepositMAT is Ownable {
    uint256 public minAmount;

    IBEP20 private MATToken;
    IBEP20 private BUSDToken;

    uint256 public price; // 6 decimal

    mapping(address => bool) public whitelist;

    enum Stage {
        Unpause,
        Pause
    }

    Stage public stage;
    bool public isPublic;

    constructor(
        address _MATAddress,
        address _BUSDAddress,
        uint256 _minAmount,
        uint256 _price
    ) {
        MATToken = IBEP20(_MATAddress);
        BUSDToken = IBEP20(_BUSDAddress);
        minAmount = _minAmount;
        price = _price;
        isPublic = true;
        stage = Stage.Unpause;
    }

    modifier requireOpen() {
        require(stage == Stage.Unpause, "Stage close");
        require(
            isPublic || whitelist[msg.sender],
            "Public sale still not open"
        );

        _;
    }

    modifier onlyWhilelist(address user) {
        require(whitelist[user], "Only whilelist");
        _;
    }

    function setWhiteList(address _whitelist, bool _isWhileList)
        public
        onlyOwner
    {
        whitelist[_whitelist] = _isWhileList;
    }

    function setStage(Stage _stage) public onlyOwner {
        stage = _stage;
    }

    function setPublic(bool _isPublic) public onlyOwner {
        isPublic = _isPublic;
    }

    function withdrawnBNB() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawnToken(address token, uint256 amount) external onlyOwner {
        require(
            IBEP20(token).balanceOf(address(this)) >= amount,
            "Token insufficient"
        );

        require(
            IBEP20(token).approve(owner(), amount),
            "Token approve failed!"
        );

        require(IBEP20(token).transfer(owner(), amount), "Token transfer fail");
    }

    function setPrice(uint256 _price) external onlyWhilelist(msg.sender) {
        price = _price;
    }

    event Desposit(address from, uint256 busd, uint256 mat, uint256 time);

    function deposit(uint256 amount) external payable requireOpen {
        require(amount >= minAmount, "Amount is too low");
        uint256 outputMAT = (amount * 1000000) / price;

        require(
            MATToken.balanceOf(address(this)) >= outputMAT,
            "MAT insufficient"
        );

        require(BUSDToken.balanceOf(msg.sender) >= amount, "BUSD insufficient");

        require(
            BUSDToken.transferFrom(msg.sender, owner(), amount),
            "BUSD transfer fail"
        );

        require(MATToken.approve(msg.sender, outputMAT), "MAT approve failed!");

        require(MATToken.transfer(msg.sender, outputMAT), "MAT transfer fail");
        emit Desposit(msg.sender, amount, outputMAT, block.timestamp);
    }
}