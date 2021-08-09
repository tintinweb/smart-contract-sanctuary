pragma solidity ^0.4.24;

import "./Withdrawable.sol";
import "./WETHInterface.sol";
import "./ERC20Interface.sol";
import "./Dextop.sol";


contract PusherTransferProxy is Withdrawable {
    mapping(address => bool) public depositAddressesStatus;
    mapping(address => bool) public shouldUnwrapWETHforDepositAddress;
    address public walletAddress;
    WETHInterface public weth;
    mapping(address => uint16) public tokenToDextopTokenCode;
    Dextop public dextop;
    address public dextopTraderAddress;

    constructor(address _walletAddress, WETHInterface _weth, Dextop _dextop, address _dextopTraderAddress) public {
        require(_walletAddress != address(0));
        require(_weth != address(0));
        require(_dextop != address(0));
        require(_dextopTraderAddress != address(0));

        walletAddress = _walletAddress;
        weth = _weth;
        dextop = _dextop;
        dextopTraderAddress = _dextopTraderAddress;
    }

    // To be able to receive ether from WETH withdraw
    function() public payable {}

    function setDepositAddress(address depositAddress, bool enabled, bool shouldUnwrapWETH) external onlyAdmin {
        require(depositAddress != address(0));

        depositAddressesStatus[depositAddress] = enabled;
        shouldUnwrapWETHforDepositAddress[depositAddress] = shouldUnwrapWETH;
    }

    event Deposit(ERC20 token, uint amount, address destination);

    function deposit(ERC20 token, uint amount, address destination) external onlyOperator returns(bool) {
        require(depositAddressesStatus[destination]);
        require(token != address(0));

        // Transfer from reserve to this contract
        require(token.transferFrom(walletAddress, this, amount));

        if (token == address(weth) && shouldUnwrapWETHforDepositAddress[destination]) {
            weth.withdraw(amount);
            destination.transfer(amount);
        } else {
            require(token.transfer(destination, amount));
        }

        emit Deposit(token, amount, destination);
        return true;
    }

    function setDextopTokenCodes(address[] tokens, uint16[] codes) external onlyAdmin {
        require(tokens.length == codes.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenToDextopTokenCode[tokens[i]] = codes[i];
        }
    }

    function approveToken(ERC20 token, address spender, uint amount) external onlyAdmin {
        require(token.approve(spender, amount));
    }

    event DextopDeposit(ERC20 token, uint amount);
    function depositToDextop(ERC20 token, uint amount) external onlyOperator returns(bool) {
        require(token != address(0));

        // Transfer from reserve to this contract
        require(token.transferFrom(walletAddress, this, amount));

        if (token == address(weth)) {
            weth.withdraw(amount);
            dextop.depositEth.value(amount)(dextopTraderAddress);
        } else {
            uint16 tokenCode = tokenToDextopTokenCode[address(token)];
            require(tokenCode != 0);
            dextop.depositToken(dextopTraderAddress, tokenCode, amount);
        }
        emit DextopDeposit(token, amount);
        return true;
    }
}