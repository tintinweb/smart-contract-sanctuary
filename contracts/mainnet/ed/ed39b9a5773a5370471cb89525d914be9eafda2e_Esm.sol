// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <=0.7.0;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(
            msg.sender == nominatedOwner,
            "You must be nominated before you can accept ownership"
        );
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner may perform this action"
        );
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

contract WhiteList is Owned {
    /// @notice Users with permissions
    mapping(address => uint256) public whiter;

    /// @notice Append address into whiteList successevent
    event AppendWhiter(address adder);

    /// @notice Remove address into whiteList successevent
    event RemoveWhiter(address remover);

    /**
     * @notice Construct a new WhiteList, default owner in whiteList
     */
    constructor() internal {
        appendWhiter(owner);
    }

    modifier onlyWhiter() {
        require(isWhiter(), "WhiteList: msg.sender not in whilteList.");
        _;
    }

    /**
     * @notice Only onwer can append address into whitelist
     * @param account The address not added, can added to the whitelist
     */
    function appendWhiter(address account) public onlyOwner {
        require(account != address(0), "WhiteList: address not zero");
        require(
            !isWhiter(account),
            "WhiteListe: the account exsit whilteList yet"
        );
        whiter[account] = 1;
        emit AppendWhiter(account);
    }

    /**
     * @notice Only onwer can remove address into whitelist
     * @param account The address in whitelist yet
     */
    function removeWhiter(address account) public onlyOwner {
        require(
            isWhiter(account),
            "WhiteListe: the account not exist whilteList"
        );
        delete whiter[account];
        emit RemoveWhiter(account);
    }

    /**
     * @notice Check whether acccount in whitelist
     * @param account Any address
     */
    function isWhiter(address account) public view returns (bool) {
        return whiter[account] == 1;
    }

    /**
     * @notice Check whether msg.sender in whitelist overrides.
     */
    function isWhiter() public view returns (bool) {
        return isWhiter(msg.sender);
    }
}


interface ITokenStake {
    function updateIndex() external;
}

contract Esm is Owned, WhiteList {
    /// @notice Access stake pause
    uint256 public stakeLive = 1;
    /// @notice Access redeem pause
    uint256 public redeemLive = 1;
    /// @notice System closed time
    uint256 public time;
    /// @notice TokenStake for updating on closed
    ITokenStake public tokenStake;

    /// @notice System closed yet event
    event ShutDown(uint256 blocknumber, uint256 time);

    /**
     * @notice Construct a new Esm
     */
    constructor() public Owned(msg.sender) {}

    /**
     * @notice Set with tokenStake
     * @param _tokenStake Address of tokenStake
     */
    function setupTokenStake(address _tokenStake) public onlyWhiter {
        tokenStake = ITokenStake(_tokenStake);
    }

    /**
     * @notice Open stake, if stake pasued
     */
    function openStake() external onlyWhiter {
        stakeLive = 1;
    }

    /**
     * @notice Paused stake, if stake opened
     */
    function pauseStake() external onlyWhiter {
        stakeLive = 0;
    }

    /**
     * @notice Open redeem, if redeem paused
     */
    function openRedeem() external onlyWhiter {
        redeemLive = 1;
    }

    /**
     * @notice Pause redeem, if redeem opened
     */
    function pauseRedeem() external onlyWhiter {
        redeemLive = 0;
    }

    /**
     * @notice Status of staking
     */
    function isStakePaused() external view returns (bool) {
        return stakeLive == 0;
    }

    /**
     * @notice Status of redeem
     */
    function isRedeemPaused() external view returns (bool) {
        return redeemLive == 0;
    }

    /**
     * @notice Status of closing-sys
     */
    function isClosed() external view returns (bool) {
        return time > 0;
    }

    /**
     * @notice If anything error, project manager can shutdown it
     *         anybody cant stake, but can redeem
     */
    function shutdown() external onlyWhiter {
        require(time == 0, "System closed yet.");
        tokenStake.updateIndex();
        time = block.timestamp;
        emit ShutDown(block.number, time);
    }
}