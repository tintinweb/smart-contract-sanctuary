pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address,uint) external;
    function transferFrom(address,address,uint) external;
    function approve(address,uint) external;
    function balanceOf(address) external view returns (uint);
}

interface IVault is IERC20 {
    function want() external view returns (address);
    function withdraw(uint) external;
    function withdrawAll() external;
    function strategy() external view returns (address);
}

interface IStrat {
    function iToken() external view returns (address);   
}

interface ICToken is IERC20 {
    function totalBorrows() external view returns (uint256);
    function borrowBalanceStored(address borrower) external view returns (uint256);
    function mint(uint tokens) external;
    function redeem(uint tokens) external;
}


interface IUniPair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

/*
    This contract flashloans required liquidity to allow withdraws to go through on the tusd beefy vault
    0.2% fee is taken from withdrawn funds to pay for flashloan fee to spookyswap tusd-usdc lp
*/
contract TUSDFlashWithdraw {
    //Flashloan source being tusd-usdc pair on spookyswap
    address _tusdFlashpair = 0x12692B3bf8dd9Aa1d2E721d1a79efD0C244d7d96;

    //Vault and assets
    address _beefyVault = 0x42ECfA11Db08FB3Bb0AAf722857be56FA8E57Dc0;

    //Interfaces to contracts in use
    IUniPair tusdPair = IUniPair(_tusdFlashpair);
    IVault vault = IVault(_beefyVault);
    IERC20 tusd = IERC20(vault.want());
    ICToken scTUSD = ICToken(IStrat(vault.strategy()).iToken());

    //Local vars to record data between flashloan
    uint debt;
    address user;

    constructor() {
        tusd.approve(address(scTUSD),type(uint256).max);
    }

    function getFlashAmount() public view returns (uint256) {
        uint base=  scTUSD.totalBorrows() - scTUSD.borrowBalanceStored(vault.strategy());
        return base;
    }
    
    function getTotalFlashFee() public view returns (uint256) {
        return (getFlashAmount() * 0.002009027 ether) / 1 ether;
    }

    function withdrawFor(address _user,uint _amount) external {
        //Transfer vault tokens
        vault.transferFrom(_user, address(this), _amount);
        
        user = _user;

        //Flashloan enough
        debt = getFlashAmount() + getTotalFlashFee();
        tusdPair.swap(0, getFlashAmount(), address(this),"fbeefy");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        require(msg.sender == _tusdFlashpair,"Wrong caller");
        //Supply tusd to scream
        scTUSD.mint(amount1);
        //call withdrawall to vault
        vault.withdrawAll();
        //Withdraw from scream
        scTUSD.redeem(scTUSD.balanceOf(address(this)));
        //Check we got more tusd than debt
        require(tusd.balanceOf(address(this)) > debt,"Dont have enough");
        //Payback flashloan with fees
        tusd.transfer(_tusdFlashpair,debt);
        //Send all remaining capital to user
        tusd.transfer(user,tusd.balanceOf(address(this)));
        //Reset debt and user for next run
        debt = 0;
        user = address(0);
    }
}