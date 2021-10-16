/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma abicoder v2;

// A partial ERC20 interface.
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// Demo contract that swaps its ERC20 balance for another ERC20.
// NOT to be used in production.
contract SimpleTokenSwap {

    struct fillOrderStruct {
        IERC20 sellToken;               // The `buyTokenAddress` field from the API response.
        IERC20 buyToken;                // The `allowanceTarget` field from the API response.
        address spender;                // The `to` field from the API response.
        address swapTarget;             // The `data` field from the API response.
        bytes swapCallData;
    }

    event BoughtTokens(IERC20 sellToken, IERC20 buyToken, uint256 boughtAmount);

    // The WETH contract.
    IWETH public immutable WETH;
    // Creator of this contract.
    address public owner;

    constructor(IWETH weth) {
        WETH = weth;        //0xc778417E063141139Fce010982780140Aa0cD5Ab
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    // Payable fallback to allow this contract to receive protocol fee refunds.
    receive() external payable {}

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawToken(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        require(token.transfer(msg.sender, amount));
    }

    // Transfer tokens held by this contrat to the sender/owner.
    function withdrawTokenBalance(IERC20 token)
    external
    onlyOwner
    {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contrat to the sender/owner.
    function withdrawETH()
        external
        onlyOwner
    {
        WETH.withdraw(WETH.balanceOf(address(this)));
        msg.sender.transfer(address(this).balance);
    }

    // Transfer ETH into this contract and wrap it into WETH.
    function depositETH()
        external
        payable
    {
        WETH.deposit{value: msg.value}();
    }

    function getBalance()
    external
    view returns (uint256)
    {
        return WETH.balanceOf(address(this));
    }

    function getTokenBalance(IERC20 token)
    external
    view returns (uint256)
    {
        return IERC20(token).balanceOf(address(this));
    }

    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function fillQuote(
        // The `sellTokenAddress` field from the API response.
        IERC20 sellToken,
        // The `buyTokenAddress` field from the API response.
        IERC20 buyToken,
        // The `allowanceTarget` field from the API response.
        address spender,
        // The `to` field from the API response.
        address payable swapTarget,
        // The `data` field from the API response.
        bytes calldata swapCallData
    )
        external
        onlyOwner
        payable // Must attach ETH equal to the `value` field from the API response.
    {
        // Track our balance of the buyToken to determine how much we've bought.
        uint256 boughtAmount = buyToken.balanceOf(address(this));

        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
        // allowance to 0 before being able to update it.
        require(sellToken.approve(spender, uint256(-1)));
        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success,) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        // Refund any unspent protocol fees to the sender.
        msg.sender.transfer(address(this).balance);

        // Use our current buyToken balance to determine how much we've bought.
        boughtAmount = buyToken.balanceOf(address(this)) - boughtAmount;
        emit BoughtTokens(sellToken, buyToken, boughtAmount);
    }


    // Swaps ERC20->ERC20 tokens held by this contract using a 0x-API quote.
    function fillQuotes(fillOrderStruct[] memory _array)
    external
    onlyOwner
    payable // Must attach ETH equal to the `value` field from the API response.
    {
        for(uint i=0; i<_array.length; i++){
            // Track our balance of the buyToken to determine how much we've bought.
            uint256 boughtAmount = _array[i].buyToken.balanceOf(address(this));

            // Give `spender` an infinite allowance to spend this contract's `sellToken`.
            // Note that for some tokens (e.g., USDT, KNC), you must first reset any existing
            // allowance to 0 before being able to update it.
            require(_array[i].sellToken.approve(_array[i].spender, uint256(-1)));
            // Call the encoded swap function call on the contract at `swapTarget`,
            // passing along any ETH attached to this function call to cover protocol fees.
            (bool success,) = _array[i].swapTarget.call{value: msg.value}(_array[i].swapCallData);
            require(success, 'SWAP_CALL_FAILED');

            // Use our current buyToken balance to determine how much we've bought.
            boughtAmount = _array[i].buyToken.balanceOf(address(this)) - boughtAmount;
            emit BoughtTokens(_array[i].sellToken, _array[i].buyToken, boughtAmount);
        }

        // Refund any unspent protocol fees to the sender.
        msg.sender.transfer(address(this).balance);

    }

}