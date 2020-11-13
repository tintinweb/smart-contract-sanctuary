pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../ProtocolInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../compound/helpers/Exponential.sol";
import "../../interfaces/ERC20.sol";

contract CompoundSavingsProtocol {

    address public constant NEW_CDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    CTokenInterface public constant cDaiContract = CTokenInterface(NEW_CDAI_ADDRESS);

    function compDeposit(address _user, uint _amount) internal {
        // get dai from user
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // mainnet only
        ERC20(DAI_ADDRESS).approve(NEW_CDAI_ADDRESS, uint(-1));

        // mint cDai
        require(cDaiContract.mint(_amount) == 0, "Failed Mint");
    }

    function compWithdraw(address _user, uint _amount) internal {
        // transfer all users balance to this contract
        require(cDaiContract.transferFrom(_user, address(this), ERC20(NEW_CDAI_ADDRESS).balanceOf(_user)));

        // approve cDai to compound contract
        cDaiContract.approve(NEW_CDAI_ADDRESS, uint(-1));
        // get dai from cDai contract
        require(cDaiContract.redeemUnderlying(_amount) == 0, "Reedem Failed");

        // return to user balance we didn't spend
        uint cDaiBalance = cDaiContract.balanceOf(address(this));
        if (cDaiBalance > 0) {
            cDaiContract.transfer(_user, cDaiBalance);
        }
        // return dai we have to user
        ERC20(DAI_ADDRESS).transfer(_user, _amount);
    }
}
