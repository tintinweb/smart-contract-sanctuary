/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed


interface DAO {
    function balanceOf(address addr)external view returns (uint);
    function transferFrom(address from, address to, uint balance) external returns (bool);
    
    
}

contract WithdrawDAONew {
    DAO  public mainDAO = DAO(0xBB9bc244D798123fDe783fCc1C72d3Bb8C189413);
    address payable public  trustee =  payable (0xeF55D78fa7CD115df8f1a70FC5902a9CE802fb91);

    function withdraw() public  {
        uint balance = mainDAO.balanceOf(msg.sender);

        mainDAO.transferFrom(msg.sender, address(this), balance) ;
        payable(msg.sender).transfer(balance);
           
    }

}