unit AccountModel;

interface

{$IF CompilerVersion >= 21.0}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished])  FIELDS([vcPublic, vcPublished])}
{$IFEND}

type

  TChangePasswordModel = class
  private
    FOldPassword :string;
    FNewPassword:string;
    FConfirmPassword:string;
  public
    property OldPassword :string read FOldPassword write FOldPassword;
    property NewPassword:string read FNewPassword write FNewPassword;
    property ConfirmPassword:string read FConfirmPassword write FConfirmPassword;
  end;

  TLogOnModel = class
  private
    FUserName :string;
    FPassword :string;
    FRememberMe :Boolean;
  public
    property UserName :string read FUserName write FUserName;
    property Password :string read FPassword write FPassword;
    property RememberMe :Boolean read FRememberMe write FRememberMe;
  end;


  TRegisterModel = class
  private
    FUserName :string;
    FEmail :string;
    FPassword :string;
    FConfirmPassword :string;
  public
    property UserName :string read FUserName write FUserName;
    property Email :string read FEmail write FEmail;
    property Password :string read FPassword write FPassword;
    property ConfirmPassword :string read FConfirmPassword write FConfirmPassword;
  end;
implementation

end.