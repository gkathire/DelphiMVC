unit HomeController;

interface

{$IF CompilerVersion >= 21.0}
  {$RTTI EXPLICIT METHODS([vcPublic, vcPublished]) PROPERTIES([vcPublic, vcPublished])  FIELDS([vcPublic, vcPublished])}
{$IFEND}

uses MvcWeb,Generics.Collections, BOClasses,BlogBLL,MvcCommon, MvcDBCommon;

type
  THomeController = class(TMvcController)
  private
    FBll:TBlogBLL;
  public
    [HttpGet]
    function Index:TMvcViewResult;overload;
    function Add:TMvcViewResult;overload;
    [HttpPost]
    function Add(Data:TPost):TMvcViewResult;overload;
    function Edit(Id:LongInt):TMvcViewResult;overload;
    [HttpPost]
    function Edit(Data:TPost):TMvcViewResult;overload;
    function List:TMvcViewResult;overload;
    [HttpPost]
    function List(SearchWord:string):TMvcViewResult;overload;
    function GetAsXml(Id:LongInt):TMvcViewResult;overload;
    function GetAsJson(Id:LongInt):TMvcViewResult;overload;
    function About:TMvcViewResult;
    constructor Create;override;
    destructor Destroy;override;
  end;

implementation

constructor THomeController.Create;
begin
  inherited Create;
  FBll:=TBlogBLL.Create;
end;

destructor THomeController.Destroy;
begin
  FBll.Destroy;
  inherited;
end;

function THomeController.Index:TMvcViewResult;
begin
  //ViewData['Message'] := 'Hello World';
  Result:=RedirectToAction('List');
end;

function THomeController.Add:TMvcViewResult;
var
  Data:TPost;
begin
  Data:= TPost.Create;
  Result:=View<TPost>(Data);
  Data.Destroy;
end;

function THomeController.Add(Data:TPost):TMvcViewResult;
begin

  if (Data = nil) then
  begin
    FlashError('Invalid Post data');
    Result:=RedirectToAction('List');
    Exit;
  end;

  if (Data.PostId > 0 ) then
  begin
    Result:=View<TPost>(Data);
    FlashError('Post Id is not valid');
    Result:=RedirectToAction('List');
    Data.Destroy;
    Exit;
  end
  else
  begin
    if FBll.AddPost(Data,ModelState) then
    begin
      FlashError('Successully saved the Post Data');
      Result:=RedirectToAction('List');
    end
    else
    begin
      FlashError('Unable to save the Post Data');
      Result:=View<TPost>(Data);
    end;
    Data.Destroy;
  end;
end;

function THomeController.Edit(Id:LongInt):TMvcViewResult;
var
  Data:TPost;
begin
  Data:= FBll.FindPostById(Id,ModelState);
  if (Data =  nil ) then
  begin
    FlashError('Unable to find Post');
    Result:=RedirectToAction('List');
    Exit;
  end;
  Result:=View<TPost>(Data);
  Data.Destroy;
end;

function THomeController.Edit(Data:TPost):TMvcViewResult;
begin
  if (Data = nil) then
  begin
    FlashError('Invalid Post data');
    Result:=RedirectToAction('List');
    Exit;
  end;

  if (Data.PostId < 1 ) then
  begin
    Result:=View<TPost>(Data);
    FlashError('Post Id is not valid');
    Result:=RedirectToAction('List');
    Data.Destroy;
    Exit;
  end
  else
  begin
    if FBll.UpdatePost(Data,ModelState) then
    begin
      FlashError('Successully updated the Post Data');
      RedirectToAction('List');
    end
    else
    begin
      FlashError('Unable to update the Post Data');
      Result:=View<TPost>(Data);
    end;
    Data.Destroy;
  end;
end;

function THomeController.List:TMvcViewResult;
var
  blogLst:TMvcList<TPost>;
begin
  blogLst:=FBll.ListPost(ModelState);
  if (blogLst = nil) then
  begin
    blogLst:= TMvcList<TPost>.Create;
    FlashError('No posts available');
  end;
  //Result:= View<TArray<TPost>>(blogLst.ToArray);
  Result:= View<TMvcList<TPost>>(blogLst);
  blogLst.Destroy;
end;

function THomeController.List(SearchWord:string):TMvcViewResult;
var
  blogLst:TMvcList<TPost>;
begin
  blogLst:=FBll.ListPost(ModelState);
  if (blogLst = nil) then
  begin
    blogLst:= TMvcList<TPost>.Create;
    FlashError('No posts available');
  end;
  Result:= View<TMvcList<TPost>>(blogLst);
  blogLst.Destroy;
end;


function THomeController.GetAsXml(Id:LongInt):TMvcViewResult;
var
  Data:TPost;
begin
  Data:= FBll.FindPostById(Id,ModelState);
  if (Data = nil ) then
  begin
    Data := TPost.Create;
    Result:=XmlView<TPost>(Data);
    Data.Destroy;
    Exit;
  end;

  Result:=XmlView<TPost>(Data);
  if (Data <> nil) then
    Data.Destroy;
end;

function THomeController.GetAsJson(Id:LongInt):TMvcViewResult;
var
  Data:TPost;
begin
  Data:= FBll.FindPostById(Id,ModelState);
  if (Data = nil ) then
  begin
    Data := TPost.Create;
    Result:=JsonView<TPost>(Data);
    Data.Destroy;
    Exit;
  end;
  Result:=JsonView<TPost>(Data);
  Data.Destroy;
end;

function THomeController.About:TMvcViewResult;
begin
  Result:=View();
end;

initialization
  THomeController.RegisterClass;

end.
