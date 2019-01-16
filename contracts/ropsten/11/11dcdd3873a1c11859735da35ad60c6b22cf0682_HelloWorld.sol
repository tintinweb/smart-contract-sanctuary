pragma solidity 0.4.25;

contract HelloWorld {
  mapping (address => HelloStruct) public hello_data;

  struct HelloStruct {
    bool checkbox_setting;
    uint8 radio_button_setting;
    int64 timepicker_setting;
    int64 datepicker_setting;
    string textbox_setting;
    string filebrowser_setting;
  }

  function registerHello(
    bool _checkbox_setting,
    uint8 _radiobutton_setting,
    int64 _datepicker_setting,
    int64 _timepicker_setting,
    string _textbox_setting,
    string _filebrowser_setting
  ) public {
      hello_data[msg.sender] = HelloStruct(_checkbox_setting,
                                           _radiobutton_setting,
                                           _datepicker_setting,
                                           _timepicker_setting,
                                           _textbox_setting,
                                           _filebrowser_setting);
  }
}