contract test{
    
    address[]  public contract_address;
    
    function add_address(address _address){
        contract_address.push(_address);
    }

    function change_address(uint256 _index, address _address){
        contract_address[_index] = _address;
    }

    function compare(address _address) view public returns(bool){
        uint i = 0;
        for (i;i<contract_address.length;i++){
            if (contract_address[i] == _address){
                return true;
            }
        }
    }
}