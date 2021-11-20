/**
 *Submitted for verification at FtmScan.com on 2021-11-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Hovse contract for user to purchase game coin with FTMO
 */

interface DUMBInterface {
    function balanceOf(address account) external returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function authorizedTransfer(address sender, address recipient, uint256 amount) external;

    function authorizedMint(address account, uint256 amount) external;

    function authorizedBurn(address account, uint256 amount) external;

    function authorizedApprove(address owner, address spender, uint256 amount) external;
}

contract DUMBHovse {

    struct PriceInfo {
        uint256 tokenAmount;
        uint256 gameCoinAmount;
    }

    address private admin;
    DUMBInterface public DUMB;
    PriceInfo[] public priceInfo;

    event Purchase(address indexed user, uint256 tokenAmount, uint256 gameCoinAmount);

    /**
     * Set the admin of this contract and receive the token address
     */
    constructor(address _admin) {
        admin = _admin;
        DUMB = DUMBInterface(0xF655aCC025570A4DE8Ce014978dce55E23041344);
    }

    /**
     * Return total number of Price options
     */
    function priceList() public view returns (uint256) {
        return priceInfo.length;
    }

    /**
     * Add new Price Info
     */
    function addPrice(uint256 _tokenAmount, uint256 _gameCoinAmount) external onlyOwner {
        require(
            _tokenAmount > 0 && _gameCoinAmount > 0,
            "Both token and game coin amount should be greater than 0."
        );

        priceInfo.push(
            PriceInfo({
                tokenAmount: _tokenAmount,
                gameCoinAmount: _gameCoinAmount
            })
        );
    }

    /**
     * Update the Price Info
     */
    function updatePrice(uint256 pid, uint256 _tokenAmount, uint256 _gameCoinAmount) external onlyOwner {
        require(pid < priceList(), "Index out of bounds");
        require(
            _tokenAmount > 0 && _gameCoinAmount > 0,
            "Both token and game coin amount should be greater than 0."
        );

        priceInfo[pid] = PriceInfo({
            tokenAmount: _tokenAmount,
            gameCoinAmount: _gameCoinAmount
        });
    }

    /**
     * Delete the Price Info
     */
    function deletePrice(uint256 pid) external onlyOwner {
        require(pid < priceList(), "Index out of bounds");
        delete priceInfo[pid];
    }

    /**
     * Update existing Price Info
     */
    function getGameCoinAmount(uint256 pid) external view returns (uint256) {
        require(pid < priceList(), "Index out of bounds");
        return priceInfo[pid].gameCoinAmount;
    }

    /**
     * Purchase Game Coin based on the Price Info
     * This transfers tokens from user to this contract
     */
    function purchase(uint256 pid) external {
        require(priceInfo[pid].tokenAmount > 0, 'Token amount should be greater than 0.');
        require(
            DUMB.allowance(msg.sender, address(this)) >= priceInfo[pid].tokenAmount,
            "Insufficient allowance."
        );
        require(
            DUMB.balanceOf(msg.sender) >= priceInfo[pid].tokenAmount,
            "Token amount should be less than the balance."
        );

        DUMB.transferFrom(msg.sender, address(this), priceInfo[pid].tokenAmount);

        emit Purchase(msg.sender, priceInfo[pid].tokenAmount, priceInfo[pid].gameCoinAmount);
    }

    // Only contract owner has the admin control
    modifier onlyOwner() {
        require(msg.sender == admin, "Only Admin is allowed.");
        _;
    }

}