// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ERC20/IBEP20.sol";
import "./access/Ownable.sol";

contract DepositPackageMAT is Ownable {
    struct Package {
        uint256 amount;
        string name;
        bool active;
    }
    mapping(uint256 => Package) packages;

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
        IBEP20 _MATAddress,
        IBEP20 _BUSDAddress,
        uint256 _price
    ) {
        MATToken = _MATAddress;
        BUSDToken = _BUSDAddress;
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

    modifier onlyWhilelist() {
        require(whitelist[_msgSender()], "Only whilelist");
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

    function setPrice(uint256 _price) external onlyWhilelist {
        price = _price;
    }

    function setPackage(
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        string[] calldata _names,
        bool[] calldata _actives
    ) external onlyOwner {
        require(_ids.length == _amounts.length, "invalid input");
        require(_ids.length == _names.length, "invalid input");
        require(_ids.length == _actives.length, "invalid input");
        for (uint256 i = 0; i < _ids.length; i++) {
            packages[_ids[i]] = Package(
                _amounts[i],
                _names[i],
                _actives[i]
            );
        }
    }

    event Buy(
        address from,
        uint256 packageId,
        uint256 amount,
        uint256 mat,
        uint256 time
    );

    function buy(uint256 _id) external requireOpen {
        require(packages[_id].active, "Package not valid");
        uint256 outputMAT = (packages[_id].amount * 1000000) / price;

        require(
            MATToken.balanceOf(address(this)) >= outputMAT,
            "MAT insufficient"
        );

        require(
            BUSDToken.balanceOf(_msgSender()) >= packages[_id].amount,
            "BUSD insufficient"
        );

        require(
            BUSDToken.transferFrom(_msgSender(), owner(), packages[_id].amount),
            "BUSD transfer fail"
        );

        require(
            MATToken.approve(_msgSender(), outputMAT),
            "MAT approve failed!"
        );

        require(
            MATToken.transfer(_msgSender(), outputMAT),
            "MAT transfer fail"
        );
        emit Buy(
            _msgSender(),
            _id,
            packages[_id].amount,
            outputMAT,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../util/Context.sol";

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

