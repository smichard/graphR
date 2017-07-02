myTable2 <- function(
  table,                      # matrix or data frame
  xpad = 1.5,                 # cell padding in x direction 
  ypad = 1.5,                 # cell padding in y direction
  text.bg = par("bg"),        # set table background colour
  header.bg = par("bg"),        # set headers background colour
  text.col = par("fg"),       # set table text colour.
  header.col = par("fg"),       # set headers text colour
  text.font = par("font"),    # set table font type.
  header.font = par("font"),    # set headers font type
  col.cex = 1.1)              # set headers text size a bit bigger than table text size
{
  

  if (dev.cur() == 1) 
    stop("Cannot add table unless a graphics device is open")

  # dim(n,m) means n+1 rows and m+1 columns, due to row and column names.
  # text located in center of each cell
  tableDim <- dim(table)
  column.names <- colnames(table)
  row.names <- rownames(table)
  
  # columns have different width, then fix cex to fix table to actual size
  # if we set same width for all cells, then set fontsise so all texts adjust to 
  # available space.
  xpad <- xpad*max(strwidth(c(letters, LETTERS), units = 'fig', cex = 1))
  ypad <- ypad*max(strheight(c(letters, LETTERS), units = 'fig', cex = 1))
  
  # column names widths
  colname.width <- rep(0, tableDim[2])
  for (column in 1:tableDim[2]) {
    colname.width[column] <- strwidth(column.names[column], 
                                      units = 'fig', 
                                      cex = col.cex) +  2*xpad
  }

  # actual table leads to another width value.
  tableWidth <- numeric(length = tableDim[2])
  for (column in 1:tableDim[2]) {
    tableWidth[column] <- max(strwidth(table[, column], 
                                       units = 'fig', 
                                       cex = 1)  ) + 2*xpad
  }
  
  bothWidths <- cbind(tableWidth, colname.width)
  allWidths <- apply(bothWidths, 1, max)
  
  recRight <- Reduce('+', allWidths, accumulate = TRUE)
  recLeft <- c(0, recRight[1:(length(recRight)-1)])
  
  headerHeight <- max(strheight(column.names, units = 'fig', cex = 1)) + 2*ypad
  
  rowHeight <- numeric(length = tableDim[1])
  for(i in 1:(tableDim[1])) {
    rowHeight[i] <- max(strheight(table[i, ], 
                               units = 'fig', 
                               cex = 1)) + 2*ypad
  }
  
  allHeights <- c(headerHeight, rowHeight)
  totalHeight <- sum(allHeights)
  recBottoms <- Reduce('+', allHeights, accumulate = T)
  recTops <- c(0, recBottoms[1:(length(recBottoms)-1)])

  xLength <- recRight[length(recRight)]
  yLength<- recBottoms[length(recBottoms)]
  
  # print(paste("xLength: ", xLength))
  # print(paste("yLength: ", yLength))
  
  if(xLength >= yLength) {
    xScale <- 1/xLength
    yScale <- xScale
  } else {
    xScale <- 1/xLength
    yScale <- 1/yLength
  }

  # print(paste("xScale: ", xScale))
  # print(paste("yScale: ", yScale))
  
  # text.bg, white background by default    
  bgMatrix <- matrix(data = "white", nrow = tableDim[1], ncol = tableDim[2])
  if (text.bg == 'banded') {
    if(tableDim[1] > 1) {
      evenrows <- seq(from = 2, to = tableDim[1], by = 2)
      bgMatrix[evenrows,] <- "lightgrey"
    }
  } else {
    bgMatrix[,] <- text.bg  # use [,] so assigment keeps matrix dimensions 
  }
  
  # header.bg = par("bg")
  if( is.character(header.bg) == T && length(header.bg) == 1) {
    # it is ok all values same color
    saveCol <- header.bg
    header.bg <- rep(saveCol, tableDim[2])
  } else if (length(header.bg) == tableDim[2]) {
    # ok by rows 
  }
  
  # text.col
  if( length(text.col) == 1) {
    # it is ok all values same color
    saveCol <- text.col
    text.col <- matrix( saveCol, nrow = tableDim[1], ncol = tableDim[2])
  } else if (length(text.col) == tableDim[1]) {
    # by rows
    saveCol <- text.col
    text.col <- matrix(' ', nrow = tableDim[1], ncol = tableDim[2])
    for (row in 1:tableDim[1]) {
      text.col[row, 1:tableDim[2]] <- saveCol[row] 
    }
  } else if  (length(text.col) == tableDim[2]) {
    # by columns
    saveCol <- text.col
    text.col <- matrix(' ', nrow = tableDim[1], ncol = tableDim[2])
    for (col in 1:tableDim[2]) {
      text.col[1:tableDim[1], col] <- saveCol[col] 
    } 
  } else {
    # consider all default value except inputs
  }
  

  # text.font 
  if( length(text.font) == 1) {
    # it is ok all values same color
    saveFont <- text.font
    text.font <- matrix(saveFont, nrow = tableDim[1], ncol = tableDim[2])
  } else if (length(text.font) == tableDim[1]) {
    # by rows
    saveFont <- text.font
    text.font <- matrix(0, nrow = tableDim[1], ncol = tableDim[2])
    for (row in 1:tableDim[1]) {
      text.font[row, 1:tableDim[2]] <- saveFont[row] 
    }
  } else if  (length(text.font) == tableDim[2]) {
    # by columns
    saveFont <- text.font
    text.font <- matrix(0, nrow = tableDim[1], ncol = tableDim[2])
    for (col in 1:tableDim[2]) {
      text.font[1:tableDim[1], col] <- saveFont[col] 
    }
  } else {
    # consider all default values except inputs
  }
  
  # rescale all variables
  scaledWidth <- xScale*xLength
  scaledHeigth <- yScale*yLength
  
  recTops <- recTops*yScale
  recBottoms <- recBottoms*yScale
  headerHeight <- headerHeight*yScale
  allHeights <- allHeights*yScale
  
  recLeft <- recLeft*xScale
  recRight <- recRight*xScale
  allWidths <- allWidths*xScale
  
  ytop <- 0.5*(1 + scaledHeigth)
  xleft <- 0.5*(1 - scaledWidth)
  
  # print(paste('xleft: ', xleft))
  # print(paste('ytop: ', ytop))

  for (column in 1:tableDim[2]) {
    rect(xleft + recLeft[column], ytop - recTops[1], 
         xleft + recRight[column],  ytop - recBottoms[1],
         col = header.bg,
         border = 'black')
    text(xleft + recLeft[column]  +0.5*allWidths[column], ytop - 0.5*headerHeight,
         column.names[column],
         cex = xScale*col.cex, 
         col = header.col,
         font = header.font)
  }
  
  for (row in 1:tableDim[1]) {

    # actual table
    for (column in 1:tableDim[2]) {
      rect(xleft + recLeft[column], ytop - recTops[row+1], 
           xleft + recRight[column], ytop - recBottoms[row+1],
           col = bgMatrix[row,column],
           border = 'black')
      text(xleft + recLeft[column] + 0.5 * allWidths[column], 
           ytop - recTops[row+1] - 0.5*allHeights[row+1] , 
           table[row, column],
           cex = min(xScale, yScale), 
           col = text.col[row,column],
           font = text.font[row,column])
    }
    par()
  }
  
}

# this function creates an slide with a ggplot and slide title-header
slidePlot <- function(plotName, 
                      slideTitle, 
                      brandName = NULL,
                      includeImg = TRUE,
                      pathImg = "./backgrounds/main_slide.png") {
  
  # ggplot is plot in this viewport
  vport <- viewport(x = 0.5, y = 0.5,
                    width = 0.9, height = 0.8)
  
  
  par(mar = c(0,0,0,0), bg = "white")
  plot.window( xlim = c(0,1), ylim = c(0,1))
  plot.new()
  
  # load image only if exists
  if(includeImg == TRUE) {
    lim <- par()
    rasterImage(readPNG(pathImg), lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  }
  
  text(x = 0.0, y = 1, slideTitle, col = "grey", cex = 3, adj = c(0,1))
  text(x = 0.8, y = 0.0, brandName, col = "brown", cex = 2, adj=c(0,0))
  
  # viewport vp is needed to define ggplot area
  plot(plotName,newpage = FALSE, vp = vport)
  
}

# this function cretes an slide with a table using plotrix function 
# addtable2plot and title-header
slideTable <- function(tableName, 
                       slideTitle, 
                       brandName = NULL,
                       leftMargin = 0.06, rightMargin = 0.03, 
                       bottomMargin = 0.12, topMargin = 0.12,
                       includeImg = TRUE,
                       pathImg = "./backgrounds/main_slide.png"
) {
  
  par(mar = c(0,0,0,0), bg = "white")
  plot.window( xlim = c(0,1), ylim = c(0,1))
  plot.new()
  
  if(includeImg == TRUE) {
    lim <- par()
    rasterImage(readPNG(pathImg), lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  }
  
  text(x = 0.0, y = 1, slideTitle, col = "grey", cex = 3, adj = c(0,1))
  text(x = 0.8, y = 0.0, brandName, col = "brown", cex = 2, adj=c(0,0))
  
  widthParameter <- 1.9 # tune it as needed, it controls long text cells width
  maxRowStr <- 1
  for(colNum in 1:ncol(tableName)) {
    tableName[ ,colNum] <- as.character(tableName[ , colNum])
    refWidth <- floor(nchar(names(tableName)[colNum])*widthParameter) 
    # print(refWidth)
    for(rowNum in 1:nrow(tableName)) {
      splitStr <- strwrap(tableName[rowNum, colNum],  width = refWidth)
      if(length(splitStr > 1)) {
        tableName[rowNum, colNum] <- paste(splitStr, collapse = "\n")
        maxRowStr <- max(maxRowStr, length(splitStr))  
      }
    }
  }
  
  def.par <- par(no.readonly = TRUE) # save default, for resetting...
  layout(mat = matrix(c(0,0,0,0,1,0,0,0,0), nrow = 3, ncol = 3, byrow = TRUE),
         widths = c(leftMargin, 1 - leftMargin - rightMargin, rightMargin),
         heights = c(topMargin, 1 - topMargin - bottomMargin, bottomMargin))
  
  myTable2(table = tableName       ,
           text.bg = "banded",         # set table background colour
           header.bg = "steelblue" ,        # set headers background colour
           # text.col = "black",         # set table text colour.
           header.col = "white"#,       # set headers text colour
           # text.font = 1,            # set table font type.
           # cols.font = 2             # ste headers font type
  )
  
  par(def.par)
}


# This function creates slide with text located in defined position
# in case text is too long to fit in one line, you can include sevral lines
# using return, each line break is taken into account by text function, don't
# use tabs if you want to keep text alignment.
slideText <- function(slideText, slideTitle, brandName = NULL,
                      includeImg = TRUE,
                      pathImg = "./backgrounds/main_slide.png") {
  
  par(mar = c(0,0,0,0), bg = "white")
  plot.window( xlim = c(0,1), ylim = c(0,1))
  plot.new()
  
  if(includeImg == TRUE) {
    lim <- par()
    rasterImage(readPNG(pathImg), lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  }
  
  
  text(x = 0.0, y = 1, slideTitle, col = "grey", cex = 3, adj = c(0,1))
  text(x = 0.8, y = 0.0, brandName, col = "brown", cex = 2, adj=c(0,0))
  
  # add text
  text(x = 0.1, y = 0.7, slideText, col = "black", cex = 2, adj = c(0, 0.5))
}

# This function creates first slide with title, author and date, all three
# parameters have default values, you just need to include them explicitly if
# you want to modify them.
slideFirst <- function(titleName ="Report", 
                       authorName = "Author",
                       documDate = Sys.Date(),
                       includeImg = TRUE,
                       pathImg = "./backgrounds/first_slide.png") {
  
  par(mar = c(0,0,0,0), bg = "grey40")
  plot.window( xlim = c(0,1), ylim = c(0,1))
  plot.new()
  
  if(includeImg == TRUE) {
    lim <- par()
    rasterImage(readPNG(pathImg), lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  }
  
  text(x = 0, y = 0.7, titleName, col = "white", cex = 4, adj = 0)
  text(x = 0, y = 0.5, authorName, col = "white", cex = 2, adj = 0)
  text(x = 0, y = 0.4, documDate, col = "white", cex = 2, adj = 0)
  
}

# This function creates last slide, it will contain an image in a regular 
# basis, if not color is black by default.
slideLast <- function(includeImg = TRUE, pathImg = "./backgrounds/last_slide.png") {
  
  par(mar = c(0,0,0,0), bg = "black")
  plot.window( xlim = c(0,1), ylim = c(0,1))
  plot.new()
  
  if(includeImg == TRUE) {
    lim <- par()
    rasterImage(readPNG(pathImg), lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  }
  
  # unccoment if you want to include text message
  # text(x = 0.5, y = 0.5, "add message if requested", col = "white", cex = 2)
  
}

# This function creates first slide with title, author and date, all three
# parameters have default values, you just need to include them explicitly if
# you want to modify them.
slideChapter <- function(titleName ="Chapter Heading", 
                       includeImg = TRUE,
                       pathImg = "./backgrounds/chapter_slide.png") {
  
  par(mar = c(0,0,0,0), bg = "grey40")
  plot.window( xlim = c(0,1), ylim = c(0,1))
  plot.new()
  
  if(includeImg == TRUE) {
    lim <- par()
    rasterImage(readPNG(pathImg), lim$usr[1], lim$usr[3], lim$usr[2], lim$usr[4])
  }
  
  text(x = 0, y = 0.7, titleName, col = "white", cex = 4, adj = 0)
}