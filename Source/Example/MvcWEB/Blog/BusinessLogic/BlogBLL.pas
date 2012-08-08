unit BlogBLL;

interface

uses BOClasses, SysUtils, StrUtils, Generics.Collections,
Generics.Defaults, BlogDAL, MvcCommon, MvcDBCommon;

type
  TBlogBLL = class
  private
    FDal:TBlogDAL;
  public
    function FindPostById(AId:LongInt;AErrorList:IMvcErrorList) : TPost;
    function DeletePostById(AId:LongInt;AErrorList:IMvcErrorList) : Boolean;
    function UpdatePost(APost:TPost;AErrorList:IMvcErrorList):Boolean;
    function AddPost(APost:TPost;AErrorList:IMvcErrorList):Boolean;
    function ListPost(AErrorList:IMvcErrorList):TMvcList<TPost>;overload;
    constructor Create;
  end;

implementation

function TBlogBLL.FindPostById(AId:LongInt;AErrorList:IMvcErrorList) : TPost;
begin
  Result:= FDal.FindPostById(AId);
end;

function TBlogBLL.DeletePostById(AId:LongInt;AErrorList:IMvcErrorList) : Boolean;
begin
  Result:= FDal.DeletePostById(AId);
end;

function TBlogBLL.UpdatePost(APost:TPost;AErrorList:IMvcErrorList):Boolean;
begin
  Result:= FDal.UpdatePost(APost);
end;

function TBlogBLL.AddPost(APost:TPost;AErrorList:IMvcErrorList):Boolean;
begin
  Result:= FDal.AddPost(APost);
end;

function TBlogBLL.ListPost(AErrorList:IMvcErrorList):TMvcList<TPost>;
begin
  Result:=FDal.ListPost();
end;

constructor TBlogBLL.Create;
begin
  inherited Create;
  FDal:=TBlogDAL.Create;
end;

end.
