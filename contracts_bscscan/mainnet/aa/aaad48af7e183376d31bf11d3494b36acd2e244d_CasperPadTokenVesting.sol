/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: UNLICENSED

// contracts/TokenVesting.sol
// SPDX-License-Identifier: Apache-2.0 (please remove thie line)
pragma solidity 0.8.5;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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

contract CasperPadTokenVesting is Context, Ownable {

    struct VestingAddress{
        uint256 amount;
        uint256 releasedCount;
    }

    address[] public members;
    uint256[] public vestingTimeList;
    string[] public vestingDateList;
    uint256 private releasedVestingId;
    mapping(address => bool) public admins;
    uint256 public constant initialTotalAmount = 225000000 ether;
    mapping(uint256 => mapping(address => VestingAddress)) public vestingTimeScheduleList;

    IBEP20 immutable public _token;

    event AddAdmin(address _address);
    event RemoveAdmin(address _address);
    event UnlockTokens(string date);
    event Withdraw(address _address, uint256 _amount);

    modifier onlyAdmin() {
        require(_msgSender() != address(0x0) && admins[_msgSender()], "Caller is not the admin");
        _;
    }

    constructor(address token_) {
        require(token_ != address(0x0));
        _token = IBEP20(token_);
        releasedVestingId = 0;

        initialData();
    }

    // create schedule data
    function initialData() private {
        // add members
        members.push(address(0x815BEe06404b43db6958a6C3f5514C34a3BA67f4));
        members.push(address(0x3D87c6B6642C2eB170edE7916E67dbdDb2B4e880));
        members.push(address(0xAb54Ac1a31609e5Ef43e3FaFb8aE9e56303980E0));
        members.push(address(0xF8090e8B05B17BC6bC99B0495AefDAcff59aE95A));
        members.push(address(0x1c8038Ebb069313dD218E8b5C1e615f15d8229B0));
        members.push(address(0x67e18eB3ad7F5981D60D9bd250BEE7faB7e6FE6D));
        members.push(address(0x505Ffa6194f6e443b86F2028b2a97A588c17b962));
        members.push(address(0x7c17740d3b41B4D838B8f769640184a871662667));
        members.push(address(0x94F1029fA7338f220adf6c2f238C3D0AbA188Be8));
        members.push(address(0x5A4AE4b9e6dBBef192412C0Ab83c0F90F4E97350));
        members.push(address(0x75076A75a263e90782b2968f9a83c34Cd56Ba099));
        members.push(address(0x369985Df2CC1B0692519f01A923271c86349F989));
        members.push(address(0xd50391f4728EDcB3799ed7Cfa5bCf7773deEE541));
        members.push(address(0x632FEf0a5BC417D0D66ED2010774336076a99452));
        members.push(address(0xe567D9FAf97b4F9F910F9e6913B07c5dE2B37084));
        members.push(address(0xb15dE4AeB7A84282aa2541A0bdAf44d18D74060f));
        members.push(address(0xBDdBD07C1783ebF90eDfcA8096e37dCeA04381E2));
        members.push(address(0xAf94bfe9AC63b11eF7F6106D1FF101693cF2a2d6));
        members.push(address(0x40Fc79BDAf528263a20054d994CDb750D6568CE9));
        members.push(address(0x08613433ad0037A0BB8c2217fAA81A0Cfb7d9d47));
        members.push(address(0x8a8DaE66246a616cE7BF2C279673F32BBf0A92B9));
        members.push(address(0x09c826E614489a3143476547d554AF7cb51D11AC));
        members.push(address(0xD21bD3E814231A61f3a1Ed196E10B253583E536c));
        members.push(address(0x8dc05A396658a90fe71241A13181459C9a87fE45));
        members.push(address(0xE478Baa3110c016fbf22708abAe74b29E8b9A9ED));
        members.push(address(0x2373Bb8bF89A82C107D82Bd2d69AebEe4e468FE2));
        members.push(address(0x9D7908e58160A69B745BDA5314a54840F70071d7));
        members.push(address(0x0C25363022587299510774E036ad078682991256));
        members.push(address(0xca6acD12f8fB7Eb5E5967A5691fF80F5585b6AB7));

        members.push(address(0x3a26ED6C70de2D4961940259830d171E160Ea145));
        members.push(address(0x358ce057301Bb8b941e0be62DeC2ec34546fe568));
        members.push(address(0x6C0e0AA11986CDc1eB466b7729FEC3fF48ED5589));

        // add schedule time
        vestingTimeList.push(1639094400); // 2021-12-10
        vestingTimeList.push(1641772800); // 2022-01-10
        vestingTimeList.push(1644451200); // 2022-02-10
        vestingTimeList.push(1646870400); // 2022-03-10
        vestingTimeList.push(1649548800); // 2022-04-10
        vestingTimeList.push(1652140800); // 2022-05-10
        vestingTimeList.push(1654819200); // 2022-06-10
        vestingTimeList.push(1657411200); // 2022-07-10
        vestingTimeList.push(1660089600); // 2022-08-10
        vestingTimeList.push(1662768000); // 2022-09-10
        vestingTimeList.push(1665360000); // 2022-10-10
        vestingTimeList.push(1668038400); // 2022-11-10
        vestingTimeList.push(1670630400); // 2022-12-10
        vestingTimeList.push(1673308800); // 2023-01-10
        vestingTimeList.push(1675987200); // 2023-02-10
        vestingTimeList.push(1678406400); // 2023-03-10
        vestingTimeList.push(1681084800); // 2023-04-10
        vestingTimeList.push(1683676800); // 2023-05-10
        vestingTimeList.push(1686355200); // 2023-06-10
        vestingTimeList.push(1688947200); // 2023-07-10
        vestingTimeList.push(1691625600); // 2023-08-10
        vestingTimeList.push(1694304000); // 2023-09-10
        vestingTimeList.push(1696896000); // 2023-10-10
        vestingTimeList.push(1699574400); // 2023-11-10
        vestingTimeList.push(1702166400); // 2023-12-10

        // add schedule time in string
        vestingDateList.push("2021-12-10");
        vestingDateList.push("2022-01-10");
        vestingDateList.push("2022-02-10");
        vestingDateList.push("2022-03-10");
        vestingDateList.push("2022-04-10");
        vestingDateList.push("2022-05-10");
        vestingDateList.push("2022-06-10");
        vestingDateList.push("2022-07-10");
        vestingDateList.push("2022-08-10");
        vestingDateList.push("2022-09-10");
        vestingDateList.push("2022-10-10");
        vestingDateList.push("2022-11-10");
        vestingDateList.push("2022-12-10");
        vestingDateList.push("2023-01-10");
        vestingDateList.push("2023-02-10");
        vestingDateList.push("2023-03-10");
        vestingDateList.push("2023-04-10");
        vestingDateList.push("2023-05-10");
        vestingDateList.push("2023-06-10");
        vestingDateList.push("2023-07-10");
        vestingDateList.push("2023-08-10");
        vestingDateList.push("2023-09-10");
        vestingDateList.push("2023-10-10");
        vestingDateList.push("2023-11-10");
        vestingDateList.push("2023-12-10");

        // private wallets

        // for 2021-10-10
        vestingTimeScheduleList[0][members[0]] = addVestingSchedule(416666.666666666 ether);
        vestingTimeScheduleList[0][members[1]] = addVestingSchedule(1250000 ether);
        vestingTimeScheduleList[0][members[2]] = addVestingSchedule(416666.666666666 ether);
        vestingTimeScheduleList[0][members[3]] = addVestingSchedule(83333.3333333333 ether);
        vestingTimeScheduleList[0][members[4]] = addVestingSchedule(416666.666666666 ether);
        vestingTimeScheduleList[0][members[5]] = addVestingSchedule(166666.666666666 ether);
        vestingTimeScheduleList[0][members[6]] = addVestingSchedule(416666.666666666 ether);
        vestingTimeScheduleList[0][members[7]] = addVestingSchedule(83333.3333333333 ether);
        vestingTimeScheduleList[0][members[8]] = addVestingSchedule(483333.3333333333 ether);
        vestingTimeScheduleList[0][members[9]] = addVestingSchedule(66666.6666666666 ether);
        vestingTimeScheduleList[0][members[10]] = addVestingSchedule(66666.6666666666 ether);
        vestingTimeScheduleList[0][members[11]] = addVestingSchedule(8333.33333333333 ether);
        vestingTimeScheduleList[0][members[12]] = addVestingSchedule(16666.6666666666 ether);
        vestingTimeScheduleList[0][members[13]] = addVestingSchedule(66666.6666666666 ether);
        vestingTimeScheduleList[0][members[14]] = addVestingSchedule(100000 ether);
        vestingTimeScheduleList[0][members[15]] = addVestingSchedule(66666.6666666666 ether);
        vestingTimeScheduleList[0][members[16]] = addVestingSchedule(66666.6666666666 ether);
        vestingTimeScheduleList[0][members[17]] = addVestingSchedule(100000 ether);
        vestingTimeScheduleList[0][members[18]] = addVestingSchedule(66666.6666666666 ether);
        vestingTimeScheduleList[0][members[19]] = addVestingSchedule(100000 ether);
        vestingTimeScheduleList[0][members[20]] = addVestingSchedule(41666.6666666666 ether);
        vestingTimeScheduleList[0][members[21]] = addVestingSchedule(20833.3333333333 ether);
        vestingTimeScheduleList[0][members[22]] = addVestingSchedule(20833.3333333333 ether);
        vestingTimeScheduleList[0][members[23]] = addVestingSchedule(20833.3333333333 ether);
        vestingTimeScheduleList[0][members[24]] = addVestingSchedule(20833.3333333333 ether);
        vestingTimeScheduleList[0][members[25]] = addVestingSchedule(208333.333333333 ether);
        vestingTimeScheduleList[0][members[26]] = addVestingSchedule(16666.6666666666 ether);
        vestingTimeScheduleList[0][members[27]] = addVestingSchedule(191666.666666666 ether);
        vestingTimeScheduleList[0][members[28]] = addVestingSchedule(1250000 ether);

        // for other months by 2022-06
        vestingTimeScheduleList[1][members[0]] = addVestingSchedule(1319444.44444444 ether);
        vestingTimeScheduleList[1][members[1]] = addVestingSchedule(3958333.33333333 ether);
        vestingTimeScheduleList[1][members[2]] = addVestingSchedule(1319444.44444444 ether);
        vestingTimeScheduleList[1][members[3]] = addVestingSchedule(263888.888888888 ether);
        vestingTimeScheduleList[1][members[4]] = addVestingSchedule(1319444.44444444 ether);
        vestingTimeScheduleList[1][members[5]] = addVestingSchedule(527777.777777777 ether);
        vestingTimeScheduleList[1][members[6]] = addVestingSchedule(1319444.44444444 ether);
        vestingTimeScheduleList[1][members[7]] = addVestingSchedule(263888.888888888 ether);
        vestingTimeScheduleList[1][members[8]] = addVestingSchedule(1530555.555555555 ether);
        vestingTimeScheduleList[1][members[9]] = addVestingSchedule(211111.111111111 ether);
        vestingTimeScheduleList[1][members[10]] = addVestingSchedule(211111.111111111 ether);
        vestingTimeScheduleList[1][members[11]] = addVestingSchedule(26388.8888888888 ether);
        vestingTimeScheduleList[1][members[12]] = addVestingSchedule(52777.7777777777 ether);
        vestingTimeScheduleList[1][members[13]] = addVestingSchedule(211111.111111111 ether);
        vestingTimeScheduleList[1][members[14]] = addVestingSchedule(316666.666666666 ether);
        vestingTimeScheduleList[1][members[15]] = addVestingSchedule(211111.111111111 ether);
        vestingTimeScheduleList[1][members[16]] = addVestingSchedule(211111.111111111 ether);
        vestingTimeScheduleList[1][members[17]] = addVestingSchedule(316666.666666666 ether);
        vestingTimeScheduleList[1][members[18]] = addVestingSchedule(211111.111111111 ether);
        vestingTimeScheduleList[1][members[19]] = addVestingSchedule(316666.666666666 ether);
        vestingTimeScheduleList[1][members[20]] = addVestingSchedule(131944.444444444 ether);
        vestingTimeScheduleList[1][members[21]] = addVestingSchedule(65972.2222222222 ether);
        vestingTimeScheduleList[1][members[22]] = addVestingSchedule(65972.2222222222 ether);
        vestingTimeScheduleList[1][members[23]] = addVestingSchedule(65972.2222222222 ether);
        vestingTimeScheduleList[1][members[24]] = addVestingSchedule(65972.2222222222 ether);
        vestingTimeScheduleList[1][members[25]] = addVestingSchedule(659722.222222222 ether);
        vestingTimeScheduleList[1][members[26]] = addVestingSchedule(52777.7777777777 ether);
        vestingTimeScheduleList[1][members[27]] = addVestingSchedule(606944.444444444 ether);
        vestingTimeScheduleList[1][members[28]] = addVestingSchedule(3958333.33333333 ether);

        // others

        // 2021-10-30
        vestingTimeScheduleList[0][members[29]] = addVestingSchedule(2500000 ether);

        // 2022-01-10 ~ 2023-12-10, for Treasury
        vestingTimeScheduleList[1][members[29]] = addVestingSchedule(1979166.66666666 ether);
        vestingTimeScheduleList[1][members[30]] = addVestingSchedule(1395833.33333333 ether);
        vestingTimeScheduleList[1][members[31]] = addVestingSchedule(687500 ether);
    }

    function addVestingSchedule(uint256 amount) private pure returns (VestingAddress memory) {
        VestingAddress memory vestingAddress = VestingAddress(amount, 0);
        return vestingAddress;
    }

    function addAdmin(address _address) external onlyOwner {
        require(_address != address(0x0), "Zero address");
        require(!admins[_address], "This address is already added as an admin");
        admins[_address] = true;
        emit AddAdmin(_address);
    }

    function removeAdmin(address _address) external onlyOwner {
        require(_address != address(0x0), "Zero address");
        require(admins[_address], "This address is not admin");
        admins[_address] = false;
        emit RemoveAdmin(_address);
    }

    function unlockToken() external onlyAdmin {
        require(releasedVestingId < 25, "Lock period End and All locked tokens were unlocked");
        uint256 currentTime = getCurrentTime();
        uint256 startTime = vestingTimeList[releasedVestingId];
        require(currentTime >= startTime, "You can't run unlockToken function now");
        if (releasedVestingId == 0) {
            require(_token.balanceOf(address(this)) >= initialTotalAmount, "You need to deposit 225000000 into this contract before you start this contract.");
        }
        uint256 indexOfSchedule = 0;
        if (releasedVestingId > 0) {
            indexOfSchedule = 1;
        }
        for (uint256 i = 0; i < members.length; i++) {
            if (releasedVestingId > 6 && i < 29) continue;
            VestingAddress memory vestingAddress = vestingTimeScheduleList[indexOfSchedule][members[i]];
            if (vestingAddress.releasedCount <= releasedVestingId) {
                require(_token.transfer(members[i], vestingAddress.amount), "Token transfer error");
                vestingTimeScheduleList[indexOfSchedule][members[i]].releasedCount++;
            }
        }
        emit UnlockTokens(vestingDateList[releasedVestingId]);
        releasedVestingId = releasedVestingId + 1;
    }

    // if admin doesn't run the unlock function in time, members can withdraw their unlocked tokens.
    function withdrawByMember() external {
        uint256 currentTime = getCurrentTime();
        uint256 indexOfSchedule = 0;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == _msgSender()) {
                for (uint256 j = 0; j < vestingTimeList.length; j++) {
                    if (j > 0) indexOfSchedule = 1;
                    if (releasedVestingId > 6 && i < 29) continue;
                    if (currentTime >= vestingTimeList[j] && vestingTimeScheduleList[indexOfSchedule][_msgSender()].releasedCount < releasedVestingId) {
                        require(_token.transfer(_msgSender(), vestingTimeScheduleList[indexOfSchedule][_msgSender()].amount), "Token transfer error");
                        vestingTimeScheduleList[indexOfSchedule][_msgSender()].releasedCount++;
                    }
                }
            }
        }
    }

    function withdrawLeftTokens() external onlyOwner {
        require(releasedVestingId >= 25, "You can't withdraw now because the vesting period is not end.");
        uint256 contractBalance = _token.balanceOf(address(this));
        require(_token.transfer(_msgSender(), contractBalance), "Token transfer error");
        emit Withdraw(_msgSender(), contractBalance);
    }

    function getCurrentTime() internal virtual view returns(uint256){
        return block.timestamp;
    }

    function getToken() external view returns(address){
        return address(_token);
    }

    function getContractBalance() external view returns(uint256) {
        return _token.balanceOf(address(this));
    }

    function getLastUnlockDate() external view returns(string memory) {
        if (releasedVestingId == 0) {
            return "Don't start unlock";
        }
        return vestingDateList[releasedVestingId - 1];
    }

    function getReleasedVestingId() external view returns(uint256) {
        return releasedVestingId;
    }
}