//***********************************************************
//
// created with pyetherchain.EtherChainAccount(address).describe_contract()
// see: https://github.com/tintinweb/pyetherchain
//
// Date:     Fri Jul 27 15:58:08 2018
//
// Name:     WithdrawDAO
// Address:  bf4ed7b27f1d666546e30d74d50d173d20bca754
// Swarm:    
//
//
// Constructor Args: constructor  () returns ()
//
//
// Transactions : <disabled>
//
//***************************
contract DAO {
    function balanceOf(address addr) returns (uint);
    function transferFrom(address from, address to, uint balance) returns (bool);
    uint public totalSupply;
}

contract WithdrawDAO {
    DAO constant public mainDAO = DAO(0xbb9bc244d798123fde783fcc1c72d3bb8c189413);
    address public trustee = 0xda4a4626d3e16e094de3225a751aab7128e96526;

    function withdraw(){
        uint balance = mainDAO.balanceOf(msg.sender);

        if (!mainDAO.transferFrom(msg.sender, this, balance) || !msg.sender.send(balance))
            throw;
    }

    function trusteeWithdraw() {
        trustee.send((this.balance + mainDAO.balanceOf(this)) - mainDAO.totalSupply());
    }
}