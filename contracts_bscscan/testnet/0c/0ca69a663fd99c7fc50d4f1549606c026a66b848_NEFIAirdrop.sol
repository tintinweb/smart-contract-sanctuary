// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./INEFIReferral.sol";

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

contract NEFIAirdrop is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;

    IBEP20 NEFIToken;
    INEFIReferral NEFIReferral;

    uint256 private constant TOTAL_LIMIT_SUPPLY = 1800000 * 1e18;
    uint256 private constant LIMIT_PER_ADDRESS = 120 * 1e18;

    uint256 totalHavest = 0;

    mapping(address => bool) existsAirdropMember;
    mapping(address => bool) existsAirdropClaimed;
    mapping(address => uint256) airdropHavests;

    event LogClaim(
        address indexed receiver,
        uint256 amountDirect,
        uint256 amountReferral,
        uint256 timestamp
    );

    constructor(IBEP20 _NEFIToken, INEFIReferral _NEFIReferral) {
        NEFIToken = _NEFIToken;
        NEFIReferral = _NEFIReferral;
    }

    modifier onlyAirdropMember() {
        require(
            existsAirdropMember[msg.sender],
            "NEFIAirdrop: caller not signup airdrop"
        );
        _;
    }

    function totalAirdropBalance() public view returns (uint256) {
        return NEFIToken.balanceOf(address(this));
    }

    function add(address receiver, uint256 amount) public onlyOwner {
        require(!existsAirdropMember[receiver]);
        require(
            totalHavest < TOTAL_LIMIT_SUPPLY,
            "NEFIAirdrop: hit limit total supply"
        );
        require(amount <= LIMIT_PER_ADDRESS, "NEFIAirdrop: invalid amount");
        uint256 saveTotalHavest = totalHavest;
        totalHavest = totalHavest.add(amount);
        existsAirdropMember[receiver] = true;

        uint256 availableAmount = TOTAL_LIMIT_SUPPLY - saveTotalHavest;
        if (availableAmount == 0) {
            revert();
        }
        uint256 totalAmount = availableAmount >= amount
            ? amount
            : availableAmount;
        airdropHavests[receiver] = totalAmount;
    }

    function claim() public onlyAirdropMember {
        require(
            !existsAirdropClaimed[msg.sender],
            "NEFIAirdrop: member already claimed"
        );
        existsAirdropClaimed[msg.sender] = true;

        uint256 amountHavest = airdropHavests[msg.sender];

        uint256 directReceived = uint256(9000).mul(amountHavest).div(10000);
        uint256 referrersReceived = amountHavest.sub(directReceived);

        require(
            NEFIToken.transfer(msg.sender, directReceived),
            "Failed transfer"
        );

        if (NEFIReferral.hasReferralPath(msg.sender)) {
            (
                address[] memory referrers,
                uint32[] memory percentLevels
            ) = NEFIReferral.referrerPath(msg.sender);

            uint256 eachAmount;

            uint256 totalPercent = 0;

            for (uint256 i = 0; i < referrers.length; i++) {
                if (referrers[i] != address(0)) {
                    eachAmount = percentLevels[i].mul(referrersReceived).div(
                        10000
                    );
                    totalPercent = totalPercent.add(percentLevels[i]);
                    NEFIToken.transfer(referrers[i], eachAmount);
                }
            }

            // remaingin percent to direct referral
            if (totalPercent < 10000) {
                uint256 remaingPercent = 10000 - totalPercent;
                eachAmount = remaingPercent.mul(referrersReceived).div(10000);
                NEFIToken.transfer(referrers[0], eachAmount);
            }
        }

        emit LogClaim(
            msg.sender,
            directReceived,
            referrersReceived,
            block.timestamp
        );
    }
}