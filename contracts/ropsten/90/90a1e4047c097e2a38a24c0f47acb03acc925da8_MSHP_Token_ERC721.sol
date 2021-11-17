/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract MSHP_Token_ERC721 {
    // адрес владельца контракта
    address owner;
    // имя токена
    string public name;
    // символ токена
    string public symbol;
    // общее количество токенов, которые могут быть выпущены
    uint public totalTokens;
    // общее количество токенов, которые уже выпущены
    uint public totalSupply;

    // индес => id токена
    mapping(uint => uint) private tokenIndex;
    // id токена => уникальное имя токена
    mapping(uint => string) private tokenName;
    // адрес => баланс токенов на нём
    mapping(address => uint) private balances;
    // id токена => адрес его владельца
    mapping(uint => address) private tokenOwners;
    // id токена => существет-нет?
    mapping(uint => bool) private tokenExists;
    // список токенов, принадлежащих адресу
    // адрес => индекс токена в списке токенов адреса => id токена
    mapping(address => mapping(uint => uint)) private ownerTokens;
    
    // словарь разрешний. Можно разрешить распоряжаться только одним токеном!
    // владелец токена => кому он разрешил распоряжаться => каким токеном
    mapping(address => mapping (address => uint)) private allowed;
    // словарь операторов
    // владелец токенов => оператор => разрешение
    mapping(address => mapping(address => bool)) private allowedAll;
    
    // проверка, что токен существует
    modifier isExists(uint _tokenId){
        require(tokenExists[_tokenId] == true, "This token does not exist");
        _;
    }
    // проверка, что функцию вызвал владелец токена
    modifier isTokenOwner(address _from, uint _tokenId){
        require(_from == tokenOwners[_tokenId], "The specified address is not the owner of the token");
        _;
    }
    
    // событие - трансфер токена
    event Transfer(address indexed _from, address indexed _to, uint _tokenId);
    // событие - разрешение на использование одного токена
    event Approval(address indexed _owner, address indexed _approved, uint _tokenId);
    // событие - разрешение на использование всех токенов
    event ApprovalAll(address indexed _owner, address indexed _operator, bool _approved);
    
    constructor(string memory _name, string memory _symbol, uint _totalTokens){
        owner = msg.sender;
        totalTokens = _totalTokens;
        totalSupply = 0;
        symbol = _symbol;
        name = _name;
    }

// ЭМИССИЯ ТОКЕНОВ

    // новый токен выпускается сразу для определённого владельца
    function mint(string memory _tokenName, address _to)public{
        require(msg.sender == owner, "You are not the owner of the contract");
        // проверяем, что не превысим максимальное количество токенов
        require(totalSupply + 1 <= totalTokens, "Issued maximum number of tokens");
        // создаём новый уникальный id
        uint tokenId = uint(blockhash(block.number - 1)) / 10 + uint(keccak256(bytes(_tokenName))) / 10;
        // проверяем, что такого id ещё нет
        require(tokenExists[tokenId] == false, "A token with this id already exists");
        
        // теперь такой токен существует
        tokenExists[tokenId] = true;
        // сохраняем его уникальное имя
        tokenName[tokenId] = _tokenName;
        
        // передаём токен владельцу
        tokenOwners[tokenId] = _to;
        
        // добавляем токен в список токенов нового владельца
        ownerTokens[_to][balances[_to]] = tokenId;
        // увеличиваем количество токенов на адресе владельца
        balances[_to] += 1;
        
        // записываем индекс нового токена
        tokenIndex[totalSupply] = tokenId;
        // увеличиваем общее количество токенов
        totalSupply += 1;
    }
    
    // возвращает количество токенов по адресу
    function balanceOf(address _owner) public view returns (uint){
        return balances[_owner];
    }
    
    // если такой токен существует, возвращает адрес его хозяина
    function ownerOf(uint _tokenId) public view isExists(_tokenId) returns (address){
        return tokenOwners[_tokenId];
    }
    
// РАЗРЕШЕНИЯ
    
    // функция для добавления в словарь разрешений
    function approve(address _to, uint _tokenId) public isTokenOwner(msg.sender, _tokenId) {
        // проверяем, что владелец токена не хочеть добавить в словарь сам себя
        require(msg.sender != _to, "The owner of the token cannot grant permission to himself");
        // то добавляем в словарь
        allowed[msg.sender][_to] = _tokenId;
        // делаем запись в событие
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    // функция передающая другому адресу (_opertor) права оператора,
    // то есть разрешение на использование всех токенов того, кто выдал это разрешение
    function setApprovalForAll(address _operator, bool _approved) external{
        allowedAll[msg.sender][_operator] = _approved;
        // делаем запись в событие
        emit ApprovalAll(msg.sender, _operator, _approved);
    }

    // проверка является ли адрес _operator авторизованным оператором другого адреса _owner
    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return allowedAll[_owner][_operator];
    }
    
// ТРАНСФЕР ТОКЕНОВ

    // собственно сам трансфер происходит в этой функции
    function transfer(address _from, address _to, uint256 _tokenId)internal{
        // изменяем владельца токена
        tokenOwners[_tokenId] = _to;
        
        // теперь надо убрать токен из списка токенов,
        // принадлежащих старому владельцу
        // находим индекс токена в этом списке
        uint index = 0;
        while(ownerTokens[_from][index] != _tokenId){
            index += 1;
        }
        // и делаем сдвиг влево в словаре. Безумие? - Блокчейн!
        for(uint i = index; i < balances[_from] - 1; i++){
            ownerTokens[_from][i] = ownerTokens[_from][i + 1];
        }
        
        // добавляем в список токнов нового владельца
        ownerTokens[_to][balances[_to]] = _tokenId;
        
        // уменьшаем количество токенов у старого владельца
        // увеличиваем у нового
        balances[_from] -= 1;
        balances[_to] += 1;
        
        // делаем запись в событие        
        emit Transfer(_from, _to, _tokenId);
    }
    
    // функция для передачи токена от одного владельца другому владельцу
    // эта функция вызывается владельцем токенов, в _from передаётся его адрес
    function transferFrom(address _from, address _to, uint256 _tokenId) external isExists(_tokenId) isTokenOwner(msg.sender, _tokenId) {
        // проверяем, что  _from указан правильный владелец
        require(msg.sender == _from, "The specified address is not the owner of the token");
        // проверяем, что новый адрес существует (не нулевой)
        require(_to != address(0), "Can't send token to zero address");
        // вызываем функцию собственно трансфера
        transfer(_from, _to, _tokenId);
    }

    // функция для передачи токена от одного владельца другому владельцу
    // эта функция вызывается владельцем токенов или адресом, кому разрешено тратить токены
    // в _from передаётся адрес владельца токенов
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external isExists(_tokenId) isTokenOwner(_from, _tokenId) {
        // проверяем, что эту функцию вызвал адрес,
        // которому разрешено распоряжаться этим адресом
        require(_tokenId == allowed[_from][msg.sender] || allowedAll[_from][msg.sender] == true, "You do not have permission to dispose of this token");
        // проверяем, что новый адрес существует (не нулевой)
        require(_to != address(0), "Can't send token to zero address");
        
        // вызываем функцию собственно трансфера
        transfer(_from, _to, _tokenId);
        
        // осталось ещё кое-что
        // поскольку владелец изменился, надо изменить словарь разрешений
        allowed[_from][msg.sender] = 0;
    }

// ИНФОРМАЦИЯ О ТОКЕНАХ

    // получение токена по индексу из общего списка токенов
    function tokenByIndex(uint _index) external view returns (uint){
        // проверяем, что такой индекс вообще есть
        require(_index < totalSupply, "A token with such an index does not exist");
        return tokenIndex[_index];
    }
    
    // получение токена по индексу в списке токенов владельца
    function tokenOfOwnerByIndex(address _owner, uint _index) public view returns (uint tokenId){
        // проверяем, что такой индекс вообще есть
        // индекс в списке должен быть меньше, чем количество токенов у _owner
        require(_index < balances[_owner], "The specified address does not have a token with this index");
        return ownerTokens[_owner][_index];
    }
    
    // получение уникального имени токена
    function getTokenNameById(uint _tokenId)public view isExists(_tokenId) returns(string memory){
        return tokenName[_tokenId];
    }
}