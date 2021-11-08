/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : - x;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
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
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused external {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused external {
        paused = false;
        Unpause();
    }
}

interface INFTPlayerRandomness {
    function getRandomNumber(uint256 _totalWeight, uint256 randomNumber) external returns (uint256);
}

interface INFTPlayerCore {
    function mint(address to, string memory metadataURI) external;
}

contract RUSaleBox is Ownable, Pausable {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    INFTPlayerCore public nftPlayer;
    IBEP20 public RU;

    // 1 - bronze , 2- silver, 3- gold
    mapping(uint256 => uint256) public price;
    mapping(uint256 => uint256) public playerQuantity;
    mapping(uint256 => uint256) public boxQuantity;

    // box type => box index => player ipfs
    mapping(uint256 => mapping(uint256 => string)) public playerBox;
    mapping(uint256 => uint256) public currentBoxIndex;
    address public signer;
    uint256 round = 0;

    event BoxSold(
        uint256 round,
        uint256 boxType,
        uint256 boxIndex,
        address buyer
    );

    constructor(INFTPlayerCore _nftPlayer, IBEP20 _RU) {
        RU = _RU;
        nftPlayer = _nftPlayer;
        price[1] = 1000e18;
        price[2] = 2000e18;
        price[3] = 3000e18;
        playerQuantity[1] = 2;
        playerQuantity[2] = 3;
        playerQuantity[3] = 4;
        boxQuantity[1] = 3;
        boxQuantity[2] = 3;
        boxQuantity[3] = 3;
        currentBoxIndex[1] = 99999999;
        currentBoxIndex[2] = 99999999;
        currentBoxIndex[3] = 99999999;
        signer = msg.sender;
    }

    function setPrice(uint256 _type, uint256 amount) public onlyOwner {
        price[_type] = amount;
    }

    function setPriceBulk(uint256 _bronze, uint256 _silver, uint256 _gold) public onlyOwner {
        price[1] = _bronze;
        price[2] = _silver;
        price[3] = _gold;
    }

    function setPlayerQuantityPerBox(uint256 _type, uint256 amount) public onlyOwner {
        playerQuantity[_type] = amount;
    }

    function setPlayerQuantityPerBoxBulk(uint256 _bronze, uint256 _silver, uint256 _gold) public onlyOwner {
        playerQuantity[1] = _bronze;
        playerQuantity[2] = _silver;
        playerQuantity[3] = _gold;
    }

    function setBoxQuantity(uint256 _type, uint256 amount) public onlyOwner {
        boxQuantity[_type] = amount;
    }

    function setBoxQuantityBulk(uint256 _bronze, uint256 _silver, uint256 _gold) public onlyOwner {
        boxQuantity[1] = _bronze;
        boxQuantity[2] = _silver;
        boxQuantity[3] = _gold;
    }

    function setRUToken(IBEP20 _RU) public onlyOwner {
        RU = _RU;
    }

    function setNFTPlayerCore(INFTPlayerCore _nftPlayer) public onlyOwner {
        nftPlayer = _nftPlayer;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setBoxPlayer(string[] memory bronze, string[] memory silver, string[] memory gold) public {
        require(msg.sender == signer, "Caller is not signer");
        require(boxQuantity[1] * playerQuantity[1] == bronze.length, "box quantity and player per bronze box not match");
        require(boxQuantity[2] * playerQuantity[2] == silver.length, "box quantity and player per silver box not match");
        require(boxQuantity[3] * playerQuantity[3] == gold.length, "box quantity and player per gold box not match");

        for(uint256 i = 0; i < bronze.length; i++) {
            playerBox[1][i] = bronze[i];
        }

        for(uint256 i = 0; i < silver.length; i++) {
            playerBox[2][i] = silver[i];
        }

        for(uint256 i = 0; i < gold.length; i++) {
            playerBox[3][i] = gold[i];
        }

        currentBoxIndex[1] = 0;
        currentBoxIndex[2] = 0;
        currentBoxIndex[3] = 0;
        round = round.add(1);
    }


    function buyBox(uint256 _type) external whenNotPaused {
        require(currentBoxIndex[_type] != 99999999, "Box is not ready!");
        require(currentBoxIndex[_type] < boxQuantity[_type], "Box is sold out!");
        require(price[_type] > 0, "Invalid Box type!");
        RU.safeTransferFrom(msg.sender, address(this), price[_type]);

        uint256 currentPlayIndex = currentBoxIndex[_type] * playerQuantity[_type];
        for (uint256 i = currentPlayIndex; i < currentPlayIndex + playerQuantity[_type]; i++) {
            nftPlayer.mint(msg.sender, playerBox[_type][i]);
        }

        currentBoxIndex[_type] = currentBoxIndex[_type].add(1);
        emit BoxSold(round, _type, currentBoxIndex[_type].sub(1), msg.sender);
    }

    function claim(IBEP20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
    }
}