/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

pragma solidity =0.8.1;

contract PolkaPetEssential {
    address public owner = 0x9dbB297557dEaBc1E22CbEd7651C25a6873aeBe9;
    bool public _saleStarted = false;
    
    function startSale() public returns (bool) {
        _saleStarted = true;
        return true;
    }
    
    function stopSale() public returns (bool) {
        _saleStarted = false;
        return false;
    }
    
    function purchaseNFT(uint256 _cardId, uint256 _amount) public returns (bool) {
        require(_saleStarted == true, "Nem aktiv bazdmeg");
        
        return true;

    }
    
}