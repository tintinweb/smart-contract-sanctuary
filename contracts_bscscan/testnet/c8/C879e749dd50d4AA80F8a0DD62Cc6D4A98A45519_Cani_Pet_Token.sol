/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

pragma solidity ^0.8.6;

contract Cani_Pet_Token {

    Pet[] public arrPet;

    struct Pet{
        string id;
        uint exp;
        uint petType;
        uint star;
        uint sex;
        uint breed;
        uint sale;
        uint saleAmount;
        uint amount;
        address wallet;
    }

    uint256 nftId = 0;
    uint8 expInit = 100;//exp khoi tao ban dau
    address caniTokenSmartContract  = 0xB28a2E0dE1A40198e342f95D1126c8C8bb882056;
    CaniInterface caniToken = CaniInterface(caniTokenSmartContract);
    address mainAddress  = 0x6c6e34BCDbFc7922C74F929f593354c0E19A5696;
    address saleAddress  = 0x6c6e34BCDbFc7922C74F929f593354c0E19A5696;
    address bonusAddress = 0x6c6e34BCDbFc7922C74F929f593354c0E19A5696;
    
    struct Error{
        uint code;
        string message;
    }

    function mint(address _sender, string memory _id, uint _petType, uint _star, uint _sex, uint _breed, uint _amount) public payable returns (uint256) {
        (bool success, bytes memory balance) = address(caniTokenSmartContract).call(
            abi.encodeWithSignature("balanceOf(address)", _sender)
        );

        require(success, 'Get balance token fail!');
        (uint256 accountBalance) = abi.decode(balance, (uint256));
        require(accountBalance >= _amount, "Ban khong du tien!");

        (bool isTransfer, bytes memory transferResult) = address(caniTokenSmartContract).call(
            abi.encodeWithSignature("transferFrom(address, address, uint256)", _sender, saleAddress, _amount)
        );

        require(isTransfer, 'Is transfer token fail!');
        (bool transfer) = abi.decode(transferResult, (bool));
        require(transfer, 'Transfer token fail!');
        
        nftId++;
        Pet memory newPet = Pet(_id, expInit, _petType, _star, _sex, _breed, 0, 0, _amount, msg.sender);
        arrPet.push(newPet);
        return nftId;
    }
    
    function userCountNumberToken(address user) public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i<nftId; i++){
            Pet memory pet = arrPet[i];
            if(user==pet.wallet){
                count = count + 1;
            }
        }
        return count;
    }

    function userGetAllToken(address user) public view returns (Pet[] memory){
        uint256 count = 0;
        Pet[] memory _appPet = new Pet[](userCountNumberToken(user));
        for(uint256 i = 0; i<nftId; i++){
            Pet memory pet = arrPet[i];
            if(user==pet.wallet){
                _appPet[count] = pet;
                count++;
            }
        }
        return _appPet;
    }
    
    function userGetTokenDetail(uint256 _petId) public view returns (Pet memory){
        Pet memory pet = arrPet[_petId];
        if(msg.sender==pet.wallet){
            return pet;
        }
        Pet memory petEmpty;
        return petEmpty;
    }

    function userDeleteToken(uint256 _petId) external returns (bool){
        Pet memory pet = arrPet[_petId];
        if(pet.wallet==msg.sender){
            delete arrPet[_petId];
            return true;
        }else{
            return false;
        }
    }

    function userUpdatePetExp(uint256 _petId, uint256 _exp) external returns (uint256){
        Pet memory pet = arrPet[_petId];
        if(pet.wallet==msg.sender){
            uint256 totalExp = pet.exp + _exp;
            arrPet[_petId].exp = totalExp;
            return totalExp;
        }else{
            return 0;
        }
    }
    
    function userSalePet(uint256 _petId, uint256 _saleAmount) external returns (bool) {
        Pet memory pet = arrPet[_petId];
        if(pet.wallet==msg.sender){
            arrPet[_petId].sale = 1;
            arrPet[_petId].saleAmount = _saleAmount;
            return true;
        }else{
            return false;
        }
    }
    
    function userBuyPet(uint256 _petId, uint256 _amount) external returns (Error memory) {
        Error memory error = Error(1, 'Data invalid!');
        Pet memory pet = arrPet[_petId];
        
        if(_amount <= 0){
            return error;
        }
        if(pet.sale==1 && pet.saleAmount == _amount){
            uint256 accountBalance = caniToken.balanceOf(msg.sender);
            if(accountBalance<_amount){
                error = Error(2, 'Insufficient account balance!');
                return error;
            }
            
            bool transfer = caniToken.transferFrom(msg.sender, arrPet[_petId].wallet, _amount);
            require(transfer==true, 'Transfer token fail!');
            if(transfer==false){
                error = Error(3, 'Transfer token fail!');
                return error;
            }
            arrPet[_petId].sale = 0;
            arrPet[_petId].saleAmount = 0;
            arrPet[_petId].amount = _amount;
            arrPet[_petId].wallet = msg.sender;
            error = Error(0, 'Transaction is succes!');
            return error;
        }else{
            return error;
        }
    }
    
    function userCountNumberTokenSale(address user) public view returns (uint256){
        uint256 count = 0;
        for(uint256 i = 0; i<nftId; i++){
            Pet memory pet = arrPet[i];
            if(user==pet.wallet){
                count = count + 1;
            }
        }
        return count;
    }
    
    function userGetAllTokenSale(address user) public view returns (Pet[] memory){
        uint256 count = 0;
        Pet[] memory _appPet = new Pet[](userCountNumberTokenSale(user));
        for(uint256 i = 0; i<nftId; i++){
            Pet memory pet = arrPet[i];
            if(user==pet.wallet && pet.sale==1){
                _appPet[count] = pet;
                count++;
            }
        }
        return _appPet;
    }
    
    function userUnSalePet(uint256 _petId) external returns (Error memory) {
        Error memory error = Error(1, 'Data invalid!');
        Pet memory pet = arrPet[_petId];
        if(pet.sale==1 && pet.wallet == msg.sender){
            arrPet[_petId].sale = 0;
            arrPet[_petId].saleAmount = 0;
            error = Error(0, 'Transaction is succes!');
            return error;
        }else{
            return error;
        }
    }
    
    function getTokenDetail(uint256 _petId) public view returns (Pet memory){
        return arrPet[_petId];
    }
    
    function transferFrom(address recipient, uint256 _petId) external returns (bool) {
        Pet memory pet = arrPet[_petId];
        if(pet.wallet==msg.sender){
            arrPet[_petId].wallet = recipient;
            return true;
        }
        return false;
    }
    
    function adminUpdateConfig(address _caniTokenSmartContract, address _saleAddress, address _bonusAddress) external returns (bool){
        if(msg.sender == mainAddress){
            caniTokenSmartContract = _caniTokenSmartContract;
            saleAddress = _saleAddress;
            bonusAddress = _bonusAddress;
            return true;
        }else{
            return false;
        }
    }
    
}


interface CaniInterface {
  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}