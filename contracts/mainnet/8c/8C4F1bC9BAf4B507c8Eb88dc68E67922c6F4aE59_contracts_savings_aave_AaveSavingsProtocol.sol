pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/IAToken.sol";
import "../../interfaces/ILendingPool.sol";
import "../../interfaces/ERC20.sol";
import "../../DS/DSAuth.sol";


contract AaveSavingsProtocol is ProtocolInterface, DSAuth {

    address public constant ADAI_ADDRESS = 0xfC1E690f61EFd961294b3e1Ce3313fBD8aa4f85d;
    address public constant AAVE_LENDING_POOL = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address public constant AAVE_LENDING_POOL_CORE = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function deposit(address _user, uint _amount) public override {
        require(msg.sender == _user);
        // get dai from user
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        ERC20(DAI_ADDRESS).approve(AAVE_LENDING_POOL_CORE, uint(-1));
        ILendingPool(AAVE_LENDING_POOL).deposit(DAI_ADDRESS, _amount, 0);

        ERC20(ADAI_ADDRESS).transfer(_user, ERC20(ADAI_ADDRESS).balanceOf(address(this)));
    }

    function withdraw(address _user, uint _amount) public override {
        require(msg.sender == _user);
        require(ERC20(ADAI_ADDRESS).transferFrom(_user, address(this), _amount));

        IAToken(ADAI_ADDRESS).redeem(_amount);

        // return dai we have to user
        ERC20(DAI_ADDRESS).transfer(_user, _amount);
    }
}
