pragma solidity ^0.4.18;

/* String utility library */
library strUtils {
    /* Converts given number to base58, limited by _maxLength symbols */
    function toBase58(uint256 _value, uint8 _maxLength) internal pure returns (string) {
        string memory letters = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
        bytes memory alphabet = bytes(letters);
        uint8 base = 58;
        uint8 len = 0;
        uint256 remainder = 0;
        bool needBreak = false;
        bytes memory bytesReversed = bytes(new string(_maxLength));

        for (uint8 i = 0; i < _maxLength; i++) {
            if(_value < base){
                needBreak = true;
            }
            remainder = _value % base;
            _value = uint256(_value / base);
            bytesReversed[i] = alphabet[remainder];
            len++;
            if(needBreak){
                break;
            }
        }

        // Reverse
        bytes memory result = bytes(new string(len));
        for (i = 0; i < len; i++) {
            result[i] = bytesReversed[len - i - 1];
        }
        return string(result);
    }

    /* Concatenates two strings */
    function concat(string _s1, string _s2) internal pure returns (string) {
        bytes memory bs1 = bytes(_s1);
        bytes memory bs2 = bytes(_s2);
        string memory s3 = new string(bs1.length + bs2.length);
        bytes memory bs3 = bytes(s3);

        uint256 j = 0;
        for (uint256 i = 0; i < bs1.length; i++) {
            bs3[j++] = bs1[i];
        }
        for (i = 0; i < bs2.length; i++) {
            bs3[j++] = bs2[i];
        }

        return string(bs3);
    }

}

contract EthTxt {

  event NewText(string text, string code, address indexed submitter, uint timestamp);

  struct StoredText {
      string text;
      address submitter;
      uint timestamp;
  }

  uint storedTextCount = 0;

  // change this to 0 for testnet / ropsten
  uint blockoffset = 5000000;

  mapping (string => StoredText) texts;

  function archiveText(string _text) public {
    // make sure _text is not an empty string
    require(bytes(_text).length != 0);

    var code = _generateShortLink();
    // make sure code doesnt exist in map
    require(bytes(getText(code)).length == 0);

    // add text to map
    texts[code] = StoredText(_text, msg.sender, now);
    NewText(_text, code, msg.sender, now);
    storedTextCount = storedTextCount + 1;
  }

  function getText(string _code) public view returns (string) {
    return texts[_code].text;
  }

  function getDataFromCode(string _code) public view returns (string, address, uint) {
    return (texts[_code].text, texts[_code].submitter, texts[_code].timestamp);
  }

  function getTextCount() public view returns (uint) {
    return storedTextCount;
  }

  // Generates a shortlink code
  function _generateShortLink() private view returns (string) {
      var s1 = strUtils.toBase58(uint256(msg.sender), 2);
      var s2 = strUtils.toBase58(block.number - blockoffset, 11);

      var s = strUtils.concat(s1, s2);
      return s;
  }

}