/**
 *Submitted for verification at BscScan.com on 2021-10-27
*/

/**
 * Interbits Open Source & Decentralized Blockchain
 *
 * Welcome to the universal currency of the people, created by the people, to empower the people.
 * No more absurd transactions fees.
 * The power of the sun and wind are the only sources of energy used to run our worldwide network.
 *
 * Made in The European Union.
 * Our headquarters are located in Stockholm Sweden, but we also have offices in Sydney Australia and and New York USA.
 * Official website: www.interbits.io
 * Telegram: Interbits
 * Reddit: Interbits
 * Created by early Bitcoin investors, Wall Street traders and some anonymous rich people.
 * Deceloped by GitHub engineers and blockchain experts from around the world..
 * We may not be the first, but we are the real deal.
 *
 * This is our security token
 * If you own any of these tokens you should feel very proud to be one of the owners of our organization.
 * Very limited supply, renounced ownership, no minting, no mining, locked liquidity forever.
 * Thank you very much for trusting us
 *
 * For utility tokens please visit our website to see a list of our projects.
 */
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library Counters{struct Counter{uint256 _value;}
function current(Counter storage counter)internal view returns(uint256){return counter._value;}
function increment(Counter storage counter)internal{unchecked{counter._value+=1;}}
function decrement(Counter storage counter)internal{uint256 value=counter._value;require(value>0,"Counter: decrement overflow");unchecked{counter._value=value-1;}}
function reset(Counter storage counter)internal{counter._value=0;}}
library ECDSA{enum RecoverError{NoError,InvalidSignature,InvalidSignatureLength,InvalidSignatureS,InvalidSignatureV}
function _throwError(RecoverError error)private pure{if(error==RecoverError.NoError){return;}else if(error==RecoverError.InvalidSignature){revert("ECDSA: invalid signature");}else if(error==RecoverError.InvalidSignatureLength){revert("ECDSA: invalid signature length");}else if(error==RecoverError.InvalidSignatureS){revert("ECDSA: invalid signature 's' value");}else if(error==RecoverError.InvalidSignatureV){revert("ECDSA: invalid signature 'v' value");}}
function tryRecover(bytes32 hash,bytes memory signature)internal pure returns(address,RecoverError){if(signature.length==65){bytes32 r;bytes32 s;uint8 v;assembly{r:=mload(add(signature,0x20))
s:=mload(add(signature,0x40))
v:=byte(0,mload(add(signature,0x60)))}
return tryRecover(hash,v,r,s);}else if(signature.length==64){bytes32 r;bytes32 vs;assembly{r:=mload(add(signature,0x20))
vs:=mload(add(signature,0x40))}
return tryRecover(hash,r,vs);}else{return(address(0),RecoverError.InvalidSignatureLength);}}
function recover(bytes32 hash,bytes memory signature)internal pure returns(address){(address recovered,RecoverError error)=tryRecover(hash,signature);_throwError(error);return recovered;}
function tryRecover(bytes32 hash,bytes32 r,bytes32 vs)internal pure returns(address,RecoverError){bytes32 s;uint8 v;assembly{s:=and(vs,0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
v:=add(shr(255,vs),27)}
return tryRecover(hash,v,r,s);}
function recover(bytes32 hash,bytes32 r,bytes32 vs)internal pure returns(address){(address recovered,RecoverError error)=tryRecover(hash,r,vs);_throwError(error);return recovered;}
function tryRecover(bytes32 hash,uint8 v,bytes32 r,bytes32 s)internal pure returns(address,RecoverError){if(uint256(s)>0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0){return(address(0),RecoverError.InvalidSignatureS);}
if(v!=27&&v!=28){return(address(0),RecoverError.InvalidSignatureV);}
address signer=ecrecover(hash,v,r,s);if(signer==address(0)){return(address(0),RecoverError.InvalidSignature);}
return(signer,RecoverError.NoError);}
function recover(bytes32 hash,uint8 v,bytes32 r,bytes32 s)internal pure returns(address){(address recovered,RecoverError error)=tryRecover(hash,v,r,s);_throwError(error);return recovered;}
function toEthSignedMessageHash(bytes32 hash)internal pure returns(bytes32){return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",hash));}
function toTypedDataHash(bytes32 domainSeparator,bytes32 structHash)internal pure returns(bytes32){return keccak256(abi.encodePacked("\x19\x01",domainSeparator,structHash));}}
abstract contract EIP712{bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;uint256 private immutable _CACHED_CHAIN_ID;bytes32 private immutable _HASHED_NAME;bytes32 private immutable _HASHED_VERSION;bytes32 private immutable _TYPE_HASH;constructor(string memory name,string memory version){bytes32 hashedName=keccak256(bytes(name));bytes32 hashedVersion=keccak256(bytes(version));bytes32 typeHash=keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");_HASHED_NAME=hashedName;_HASHED_VERSION=hashedVersion;_CACHED_CHAIN_ID=block.chainid;_CACHED_DOMAIN_SEPARATOR=_buildDomainSeparator(typeHash,hashedName,hashedVersion);_TYPE_HASH=typeHash;}
function _domainSeparatorV4()internal view returns(bytes32){if(block.chainid==_CACHED_CHAIN_ID){return _CACHED_DOMAIN_SEPARATOR;}else{return _buildDomainSeparator(_TYPE_HASH,_HASHED_NAME,_HASHED_VERSION);}}
function _buildDomainSeparator(bytes32 typeHash,bytes32 nameHash,bytes32 versionHash)private view returns(bytes32){return keccak256(abi.encode(typeHash,nameHash,versionHash,block.chainid,address(this)));}
function _hashTypedDataV4(bytes32 structHash)internal view virtual returns(bytes32){return ECDSA.toTypedDataHash(_domainSeparatorV4(),structHash);}}
interface Transactions{function permit(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)external;function nonces(address owner)external view returns(uint256);function DOMAIN_SEPARATOR()external view returns(bytes32);}
abstract contract Reliable{function _msgSender()internal view virtual returns(address){return msg.sender;}
function _msgData()internal view virtual returns(bytes calldata){return msg.data;}}
interface Unique{function totalSupply()external view returns(uint256);function balanceOf(address account)external view returns(uint256);function transfer(address recipient,uint256 amount)external returns(bool);function allowance(address owner,address spender)external view returns(uint256);function approve(address spender,uint256 amount)external returns(bool);function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);event Transfer(address indexed from,address indexed to,uint256 value);event Approval(address indexed owner,address indexed spender,uint256 value);}
interface Interactive is Unique{function name()external view returns(string memory);function symbol()external view returns(string memory);function decimals()external view returns(uint8);}
contract Secure is Reliable,Unique,Interactive{mapping(address=>uint256)private _balances;mapping(address=>mapping(address=>uint256))private _allowances;uint256 private _totalSupply;string private _name;string private _symbol;constructor(string memory name_,string memory symbol_){_name=name_;_symbol=symbol_;}
function name()public view virtual override returns(string memory){return _name;}
function symbol()public view virtual override returns(string memory){return _symbol;}
function decimals()public view virtual override returns(uint8){return 18;}
function totalSupply()public view virtual override returns(uint256){return _totalSupply;}
function balanceOf(address account)public view virtual override returns(uint256){return _balances[account];}
function transfer(address recipient,uint256 amount)public virtual override returns(bool){_transfer(_msgSender(),recipient,amount);return true;}
function allowance(address owner,address spender)public view virtual override returns(uint256){return _allowances[owner][spender];}
function approve(address spender,uint256 amount)public virtual override returns(bool){_approve(_msgSender(),spender,amount);return true;}
function transferFrom(address sender,address recipient,uint256 amount)public virtual override returns(bool){_transfer(sender,recipient,amount);uint256 currentAllowance=_allowances[sender][_msgSender()];require(currentAllowance>=amount,"Secure: transfer amount exceeds allowance");unchecked{_approve(sender,_msgSender(),currentAllowance-amount);}
return true;}
function increaseAllowance(address spender,uint256 addedValue)public virtual returns(bool){_approve(_msgSender(),spender,_allowances[_msgSender()][spender]+addedValue);return true;}
function decreaseAllowance(address spender,uint256 subtractedValue)public virtual returns(bool){uint256 currentAllowance=_allowances[_msgSender()][spender];require(currentAllowance>=subtractedValue,"Secure: decreased allowance below zero");unchecked{_approve(_msgSender(),spender,currentAllowance-subtractedValue);}
return true;}
function _transfer(address sender,address recipient,uint256 amount)internal virtual{require(sender!=address(0),"Secure: transfer from the zero address");require(recipient!=address(0),"Secure: transfer to the zero address");_beforeTokenTransfer(sender,recipient,amount);uint256 senderBalance=_balances[sender];require(senderBalance>=amount,"Secure: transfer amount exceeds balance");unchecked{_balances[sender]=senderBalance-amount;}
_balances[recipient]+=amount;emit Transfer(sender,recipient,amount);_afterTokenTransfer(sender,recipient,amount);}
function _mint(address account,uint256 amount)internal virtual{require(account!=address(0),"Secure: mint to the zero address");_beforeTokenTransfer(address(0),account,amount);_totalSupply+=amount;_balances[account]+=amount;emit Transfer(address(0),account,amount);_afterTokenTransfer(address(0),account,amount);}
function _burn(address account,uint256 amount)internal virtual{require(account!=address(0),"Secure: burn from the zero address");_beforeTokenTransfer(account,address(0),amount);uint256 accountBalance=_balances[account];require(accountBalance>=amount,"Secure: burn amount exceeds balance");unchecked{_balances[account]=accountBalance-amount;}
_totalSupply-=amount;emit Transfer(account,address(0),amount);_afterTokenTransfer(account,address(0),amount);}
function _approve(address owner,address spender,uint256 amount)internal virtual{require(owner!=address(0),"Secure: approve from the zero address");require(spender!=address(0),"Secure: approve to the zero address");_allowances[owner][spender]=amount;emit Approval(owner,spender,amount);}
function _beforeTokenTransfer(address from,address to,uint256 amount)internal virtual{}
function _afterTokenTransfer(address from,address to,uint256 amount)internal virtual{}}
abstract contract Universal is Secure,Transactions,EIP712{using Counters for Counters.Counter;mapping(address=>Counters.Counter)private _nonces;bytes32 private immutable _PERMIT_TYPEHASH=keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");constructor(string memory name)EIP712(name,"1"){}
function permit(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)public virtual override{require(block.timestamp<=deadline,"Universal: expired deadline");bytes32 structHash=keccak256(abi.encode(_PERMIT_TYPEHASH,owner,spender,value,_useNonce(owner),deadline));bytes32 hash=_hashTypedDataV4(structHash);address signer=ECDSA.recover(hash,v,r,s);require(signer==owner,"Universal: invalid signature");_approve(owner,spender,value);}
function nonces(address owner)public view virtual override returns(uint256){return _nonces[owner].current();}
function DOMAIN_SEPARATOR()external view override returns(bytes32){return _domainSeparatorV4();}
function _useNonce(address owner)internal virtual returns(uint256 current){Counters.Counter storage nonce=_nonces[owner];current=nonce.current();nonce.increment();}}
abstract contract Decentralized is Reliable,Secure{function burn(uint256 amount)public virtual{_burn(_msgSender(),amount);}
function burnFrom(address account,uint256 amount)public virtual{uint256 currentAllowance=allowance(account,_msgSender());require(currentAllowance>=amount,"Secure: burn amount exceeds allowance");unchecked{_approve(account,_msgSender(),currentAllowance-amount);}
_burn(account,amount);}}
contract Interbits is Secure,Decentralized,Universal{constructor()Secure("Interbits","BIT")Universal("Interbits"){_mint(msg.sender,100000000*10**decimals());}}