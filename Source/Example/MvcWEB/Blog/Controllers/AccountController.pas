unit AccountController;

interface

{$IF CompilerVersion >= 21.0}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished])  FIELDS([vcPublic, vcPublished])}
{$IFEND}

uses MvcWeb,Generics.Collections, AccountModel;

type
  TAccountController = class(TMvcController)
  public
    function Index:TMvcViewResult;overload;
    function ChangePassword:TMvcViewResult;overload;
    function LogOn:TMvcViewResult;overload;
    function Register:TMvcViewResult;overload;
    [HttpPost]
    function ChangePassword(model:TChangePasswordModel):TMvcViewResult;overload;
    [HttpPost]
    function LogOn(model:TLogOnModel):TMvcViewResult;overload;
    [HttpPost]
    function Register(model:TRegisterModel):TMvcViewResult;overload;

  end;

implementation


function TAccountController.Index:TMvcViewResult;
begin
  Result:= RedirectToAction('LogOn');
end;

function TAccountController.ChangePassword:TMvcViewResult;
var
  model:TChangePasswordModel;
begin
  model:=TChangePasswordModel.Create;
  Result:= View<TChangePasswordModel>(model);
  model.Destroy;
end;

function TAccountController.ChangePassword(model:TChangePasswordModel):TMvcViewResult;
begin
  Result:= View<TChangePasswordModel>(model);
end;

function TAccountController.LogOn:TMvcViewResult;
var
  model:TLogOnModel;
begin
  model:=TLogOnModel.Create;
  Result:= View<TLogOnModel>(model);
  model.Destroy;
end;

function TAccountController.LogOn(model:TLogOnModel):TMvcViewResult;
begin
  Result:= View<TLogOnModel>(model);
end;

function TAccountController.Register:TMvcViewResult;
var
  model:TRegisterModel;
begin
  model:=TRegisterModel.Create;
  Result:= View<TRegisterModel>(model);
  model.Destroy;
end;

function TAccountController.Register(model:TRegisterModel):TMvcViewResult;
begin
  Result:= View<TRegisterModel>(model);
end;

initialization
  TAccountController.RegisterClass;

end.
